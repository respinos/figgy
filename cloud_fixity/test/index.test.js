require('dotenv').config()
const checkFixity = require('..').checkFixity
const fs = require('fs')
const { Readable } = require('stream');
class RequestError extends Error {
}

// Mock Cloud Storage
const { Storage } = require('@google-cloud/storage')
jest.mock('@google-cloud/storage')
const file = jest.fn()
const bucket = jest.fn(() => ({ file }))
beforeEach(() => {
  file.mockImplementation(name => ({
    createReadStream: () => {
      return fs.createReadStream(`cloud_fixity/test/fixtures/${name}`)
    }
  }))
})

// Mock PubSub
const { PubSub } = require('@google-cloud/pubsub')
jest.mock('@google-cloud/pubsub')
var publishStatusJSON = jest.fn(() => {
  return new Promise((resolve, reject) => { resolve() })
})
var publishRequestJSON = jest.fn(() => {
  return new Promise((resolve, reject) => { resolve() })
})

const topic = jest.fn(function(name) {
  let publishFunction = null
  if(name == "figgy-staging-fixity-status") {
    publishFunction = publishStatusJSON
  } else {
    publishFunction = publishRequestJSON
  }
  return { publishJSON: publishFunction }
})

Storage.mockImplementation(() => ({ bucket }))
PubSub.mockImplementation(() => ({ topic }))

describe('when given a good MD5', () => {
  test('succeeds', async () => {
    const attributes = {
      preservation_object_id: '1',
      file_metadata_node_id: '1',
      cloudPath: 'example.tif',
      md5: '2a28fb702286782b2cbf2ed9a5041ab1',
      child_property: 'bla'
    }
    const event = {
      data: Buffer.from(JSON.stringify(attributes)).toString('base64')
    }
    await checkFixity(event)
    expect(publishStatusJSON).toBeCalledWith({
      status: 'SUCCESS',
      resource_id: '1',
      child_id: '1',
      child_property: 'bla'
    })
  })
})

describe('when the stream errors', () => {
  beforeEach(() => {
     let myReadable = new Readable({
      read(size) {
        const mismatchError = new RequestError([
          'The downloaded data did not match the data from the server.',
          'To be sure the content is the same, you should download the',
          'file again.',
        ].join(' '));
        process.nextTick(() => this.emit('error', mismatchError));
        this.push(null)
      }
    });

    file.mockImplementation(name => ({
      createReadStream: () => {
        return myReadable
      }
    }))
  })

  test('retries', async () => {
    const attributes = {
      preservation_object_id: '1',
      file_metadata_node_id: '1',
      cloudPath: 'example.tif',
      md5: '2a28fb702286782b2cbf2ed9a5041ab1',
      child_property: 'bla'
    }
    const event = {
      data: Buffer.from(JSON.stringify(attributes)).toString('base64')
    }
    await checkFixity(event)
    expect(publishRequestJSON).toBeCalledWith({
      preservation_object_id: '1',
      file_metadata_node_id: '1',
      cloudPath: 'example.tif',
      md5: '2a28fb702286782b2cbf2ed9a5041ab1',
      child_property: 'bla',
      retry_count: 1
    })
  })

  test('fails eventually', async () => {
    const attributes = {
      preservation_object_id: '1',
      file_metadata_node_id: '1',
      cloudPath: 'example.tif',
      md5: '2a28fb702286782b2cbf2ed9a5041ab1',
      child_property: 'bla',
      retry_count: 5
    }
    const event = {
      data: Buffer.from(JSON.stringify(attributes)).toString('base64')
    }
    await checkFixity(event)
    expect(publishStatusJSON).toBeCalledWith({
      status: 'FAILURE',
      resource_id: '1',
      child_id: '1',
      child_property: 'bla'
    })
  })
})

describe('when given a bad MD5', () => {
  beforeEach(() => {
    file.mockImplementation(name => ({
      createReadStream: () => {
        return fs.createReadStream(`cloud_fixity/test/fixtures/${name}`)
      }
    }))
  })
  test('fails', async () => {
    const attributes = {
      preservation_object_id: '1',
      file_metadata_node_id: '1',
      cloudPath: 'example.tif',
      md5: '123',
      child_property: 'bla'
    }
    const event = {
      data: Buffer.from(JSON.stringify(attributes)).toString('base64')
    }
    await checkFixity(event)
    expect(publishStatusJSON).toBeCalledWith({
      status: 'FAILURE',
      resource_id: '1',
      child_id: '1',
      child_property: 'bla'
    })
  })
})
