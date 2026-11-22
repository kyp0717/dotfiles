# Lesson: conditionally loading an env file in nushell needs a runtime parse, not `source`

Date: 2026-11-22. Machine: woodlawn. Surfaced while fixing the
`source ~/.alpaca.env` line that the linden -> woodlawn transfer added
to `config.nu` (woodlawn has no `~/.alpaca.env`, so startup would
error).

## What happened

`config.nu` ended with:

```nu
source ~/.alpaca.env
```

`source` is a parse-time keyword in nushell: the file must exist when
`config.nu` is parsed. A guard like `if (file exists) { source ... }`
still fails on machines without the file, because the parse happens
before the `if` runs. First workaround attempt, `open file | from env`,
also failed: this nushell build (0.114.1) has no `from env` subcommand
(`help from` lists csv/json/toml/yaml/... only), and the error
("extra positional argument", usage shows bare `from`) does not say the
subcommand is missing.

## Why it happened

Two separate platform facts: nushell keeps `source`/`source-env`
parse-time by design, and `from env` is absent from the 0.114.1 build
installed here (some builds trim format subcommands).

## The fix

Runtime parse-and-load in `nushell/.config/nushell/config.nu`:

```nu
let alpaca_env = ($env.HOME | path join ".alpaca.env")
if ($alpaca_env | path exists) {
  let vars = (open $alpaca_env
    | lines
    | where $it !~ '^\s*(#|$)'
    | parse "{key}={value}"
    | transpose -r)
  if not ($vars | is-empty) {
    load-env ($vars | first)
  }
}
```

Verified on woodlawn: config sources clean with no file, and
`APCA_API_KEY_ID` loads when a file is present. `parse "{key}={value}"`
keeps `=` inside values; the empty-file case is guarded by `is-empty`
because `first` on an empty stream errors.

## Rules that fall out

- Never guard a `source` with `if` for optional files; it breaks at
  parse time on machines without the file.
- Check `help from` before assuming a `from <fmt>` subcommand exists;
  prefer the lines/parse/transpose/load-env pattern for dotenv files.
- Regex strings for `where`/`str replace`: use single quotes
  (`'\s'`), double-quoted `"\s"` is an invalid escape in nu.
