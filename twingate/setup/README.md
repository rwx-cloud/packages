# twingate/setup

To install & setup the latest version of Twingate:

 ```yaml
 tasks:
   - key: twingate
     call: twingate/setup 1.0.7
     with:
       twingate-service-key: ${{ secrets.twingate-service-key }}
 ```


In the task that needs to connect to Twingate:

```yaml
tasks:
  - key: example-that-uses-twingate
    use: twingate
    background-processes:
      - key: twingate
        run: sudo twingate start
        ready-check: |
          # print full output for observability
          twingate status

          # make sure it is online
          twingate status | grep online
    run: ...
```

For more information on using Twingate, see the [Twingate documentation](https://www.twingate.com/docs/linux).
