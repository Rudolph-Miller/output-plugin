aws = require 'aws-sdk'

class OutputPlugin
  constructor: (option={}) ->
    @config.awsCredential (option.awsCredential) if option.awsCredential
    if option.dynamo
      @dynamo = new aws.DynamoDB
      if typeof option.dynamo == 'object'
        for table in option.dynamo
          @dynamoConfig table
      else
        @dynamoConfig option.dynamo
    @logType = option.logType if option.logType

  convert: (log, callback) ->
    if @logType
      @selectType @logType, log, callback
    else
      try
        callback null, JSON.parse log
      catch error
        callback error

  selectType: (type, log, callback) ->
    switch type
      when 'tsv'
        @tsvParse log, callback
      when 'csv'
        @csvParse log, callback
      else
        console.log 'not supported type'
        callback 'not supported type'

  emit: (log) ->
    console.log @convert log.data

  tsvParse: (log, callback) ->
    try
      array = log.split('\t')
      result = []
      for item in array
        kv = item.split(':')
        key = kv[0]
        val = kv.slice(1).join(':')
        result[key] = val
      callback null, result
    catch error
      callback error

  csvParse: (log) ->
    try
      array = log.split(',')
      result = []
      for item in array
        kv = item.split(':')
        key = kv[0]
        val = kv.slice(1).join(':')
        result[key] = val
      callback null, result
    catch error
      callback error

  config:
    awsCredential: (path) ->
      aws.config.loadFromPath path

  dynamoConfig: (table) ->
    this[table] = {}
    params =
      TableName: table
    this[table].putItem = (item) =>
      params.Item = item
      @dynamo.putItem params, (err, data, callback) ->
        if err
          callback err
        else
          callback null, data
    this[table].getItem = (option, callback) =>
      params.Key = option.Key
      params.AttributesToGet = option.AttributesToGet if option.AttributesToGet
      @dynamo.getItem params, (err, data) ->
        if err
          callback err
        else
          callback null, data

module.exports = OutputPlugin
