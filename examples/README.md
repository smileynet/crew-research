# Example Projects

Sample project configurations demonstrating per-project customization.

## Usage

Generate a deployment for a sample project:

```bash
# Generate kiro-cli deployment for the Rust CLI example
tools/generator/generate.sh generate --project examples/rust-cli --tool kiro-cli --output /tmp/my-deploy

# Generate for the Node webapp
tools/generator/generate.sh generate --project examples/node-webapp --tool kiro-cli --output /tmp/my-deploy
```

Then copy the generated `.kiro/` directory into your actual project.

## Examples

| Project | Crews | Agents | Verification |
|---------|-------|:------:|--------------|
| rust-cli | development, bugfix | 7 | cargo check/test/clippy |
| node-webapp | development, documentation | 6 | npm build/test/lint |
