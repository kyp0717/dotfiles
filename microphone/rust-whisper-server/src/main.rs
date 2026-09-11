use axum::{
    extract::Multipart,
    response::{IntoResponse, Json},
    routing::{get, post},
    Router,
};
use serde_json::json;
use std::sync::Arc;
use whisper_rs::{FullParams, SamplingStrategy, WhisperContext, WhisperContextParameters};

struct AppState {
    ctx: WhisperContext,
}

#[tokio::main]
async fn main() {
    // The backend is chosen at build time by run.sh: --features cuda on
    // NVIDIA machines (linden), default CPU build otherwise (woodlawn).
    let backend = if cfg!(feature = "cuda") { "cuda" } else { "cpu" };
    println!("Loading GGML Whisper model (backend: {backend})...");

    // 1. Initialize Whisper C++ context from local GGML model
    let mut ctx_params = WhisperContextParameters::default();
    // use_gpu defaults to the compiled backend; WHISPER_USE_GPU=0 forces CPU
    // on a CUDA build (useful for debugging).
    if let Ok(v) = std::env::var("WHISPER_USE_GPU") {
        ctx_params.use_gpu(!matches!(v.as_str(), "0" | "false" | "no"));
    }
    let ctx = WhisperContext::new_with_params("ggml-base.bin", ctx_params)
        .expect("Failed to load ggml-base.bin model file");

    let state = Arc::new(AppState { ctx });

    // 2. Build OpenAI-compatible HTTP endpoints
    let app = Router::new()
        .route("/v1/audio/transcriptions", post(transcribe_handler))
        .route("/health", get(health_handler))
        .with_state(state);

    println!("Rust Whisper Server running on http://0.0.0.0:10301");
    let listener = tokio::net::TcpListener::bind("0.0.0.0:10301").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_handler() -> &'static str {
    "OK"
}

async fn transcribe_handler(
    axum::extract::State(state): axum::extract::State<Arc<AppState>>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    let mut audio_bytes = Vec::new();

    // Parse the incoming multipart form payload
    while let Ok(Some(field)) = multipart.next_field().await {
        if field.name() == Some("file") {
            if let Ok(bytes) = field.bytes().await {
                audio_bytes = bytes.to_vec();
            }
        }
    }

    if audio_bytes.is_empty() {
        return (
            axum::http::StatusCode::BAD_REQUEST,
            Json(json!({"error": "No file uploaded"})),
        );
    }

    // Process transcription on a dedicated blocking thread pool
    let ctx = Arc::clone(&state);
    let result = tokio::task::spawn_blocking(move || process_audio(&ctx.ctx, audio_bytes)).await;

    match result {
        Ok(Ok(text)) => (axum::http::StatusCode::OK, Json(json!({ "text": text }))),
        _ => (
            axum::http::StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Failed to transcribe audio"})),
        ),
    }
}

fn process_audio(ctx: &WhisperContext, bytes: Vec<u8>) -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
    // 1. Decode WAV bytes into 16kHz mono PCM float samples
    let cursor = std::io::Cursor::new(bytes);
    let reader = hound::WavReader::new(cursor)?;
    let spec = reader.spec();

    let samples: Vec<f32> = match spec.sample_format {
        hound::SampleFormat::Int => reader
            .into_samples::<i16>()
            .map(|s| s.map(|v| v as f32 / 32768.0))
            .collect::<Result<Vec<f32>, _>>()?,
        hound::SampleFormat::Float => reader.into_samples::<f32>().collect::<Result<Vec<f32>, _>>()?,
    };

    // 2. Configure Whisper inference parameters. Thread count is per-machine
    // (see sync/MACHINES.md): 16 on woodlawn's Threadripper. With the cuda
    // backend the GPU does the heavy lifting and threads matter less.
    let n_threads: i32 = std::env::var("WHISPER_THREADS")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(16);
    let mut params = FullParams::new(SamplingStrategy::Greedy { best_of: 1 });
    params.set_n_threads(n_threads);
    params.set_print_special(false);
    params.set_print_progress(false);
    params.set_print_realtime(false);
    params.set_print_timestamps(false);

    // 3. Run Inference
    let mut state = ctx.create_state()?;
    state.full(params, &samples[..])?;

    // 4. Extract string output
    let num_segments = state.full_n_segments()?;
    let mut text = String::new();
    for i in 0..num_segments {
        if let Ok(segment) = state.full_get_segment_text(i) {
            text.push_str(&segment);
        }
    }

    Ok(text.trim().to_string())
}
