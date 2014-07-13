OutputPlugin for Log Emitter

1. Option
  * option.awsCredential = *credential-path* for aws.
  * option.dynamo = *tablename* for DynamoDB.
    * *tablename* is string or array.
    * when you set this option, method of *tablename* will be created.
    ```
    option.awsCredential = 'path-to-awscredentail'
    optioin.dynamo = 'tablename'
    plugin = new OutputPlugin option
    item =
      id:
        S: 'abc'
      date:
        N: '20140630'
    plugin.tablename.pugItem item, callback
    plugin.tablename.getItem item, callback
    ```
  * option.logType = type of log
    * 'tsv'
      * 'key1:val1\tkey2:val2' -> { key1: 'val1', key2: 'val2'}
    * 'csv'
      * 'key1:val1,key2:val2' -> { key1: 'val1', key2: 'val2' }

2. Method
  * emit: (log) ->
      do somethig with log.data
