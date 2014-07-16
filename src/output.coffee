aws = require 'aws-sdk'

class OutputPlugin
  constructor: (option={}) ->
    aws.config.loadFromPath option.awsCredential if option.awsCredential
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
    this[table].putItem = (item, callback) =>
      putParams =
        TableName: table
        Item: item
      @dynamo.putItem putParams, (err, data) ->
        if err
          callback err
        else
          callback null, data
    this[table].getItem = (option, callback) =>
      getParams =
        TableName: table
        Key: option.Key
      getParams.AttributesToGet = option.AttributesToGet if option.AttributesToGet
      @dynamo.getItem getParams, (err, data) ->
        if err
          callback err
        else
          callback null, data
    this[table].increment = (item, callback) =>
      updateParams =
        TableName: table
        Key: item.getKey
        AttributeUpdates: {}
        Expected: {}
      updateParams.ConditionalOperator = 'AND' if Object.keys(item.getKey).length > 1
      for key in Object.keys(item.getKey)
        updateParams.Expected[key] =
          Value: item.getKey[key]
          Exists: true
      updateParams.AttributeUpdates[item.updateAttribute] =
        Action: 'ADD'
        Value:
          N: '1'
      @dynamo.updateItem updateParams, (err, data) =>
        if err
          putParams =
            TableName: table
            Item: item.Key
          @dynamo.putItem  putParams, (err, data) ->
            if err
              callback err
            else
              callback null, data
        else
          callback null, data


option =
  awsCredential: '/Users/tomoya/git-lab/lambda-driver/config/aws_credentials.json'
  dynamo: 'sometracking'

module.exports = OutputPlugin
