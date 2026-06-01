# Unix Shell Safety (Linux/macOS)

## Long-Running Commands

```bash
nohup <command> > /tmp/output.log 2>&1 &
```

Check status:
```bash
kill -0 $! 2>/dev/null && echo "running" || echo "done"
tail -50 /tmp/output.log
```
