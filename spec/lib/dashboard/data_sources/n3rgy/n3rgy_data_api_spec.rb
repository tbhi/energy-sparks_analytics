# frozen_string_literal: true

require 'spec_helper'
require 'faraday/adapter/test'

describe MeterReadingsFeeds::N3rgyDataApi do
  let(:stubs)           { Faraday::Adapter::Test::Stubs.new }
  let(:connection)      { Faraday.new { |b| b.adapter(:test, stubs) } }
  let(:base_url)        { 'http://api.example.org' }
  let(:api_token)       { 'token' }

  let(:api)             { described_class.new(api_token, base_url, connection) }

  let(:mpxn)            { '123456789100' }
  let(:fuel_type)       { :electricity }

  let(:headers)         { { "Authorization": 'foo' } }

  after(:all) do
    Faraday.default_connection = nil
  end

  describe '#new' do
    it 'adds auth header when constructing client' do
      allow(Faraday).to receive(:new).with(base_url, headers: { 'Authorization' => api_token }).and_call_original
      described_class.new(api_token, base_url)
    end
  end

  describe '#fetch' do
    context 'with auth failure' do
      let(:response) { { "message": 'Unauthorized' } }

      it 'raises error' do
        stubs.get('some-inventory-file') do |_env|
          [401, {}, 'no way']
        end
        expect do
          api.fetch('some-inventory-file')
        end.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotAuthorised, 'no way')
        stubs.verify_stubbed_calls
      end
    end

    context 'with retry' do
      it 'retries and then raises error' do
        expect(api).to receive(:get_data).exactly(4).times.and_raise(MeterReadingsFeeds::N3rgyDataApi::NotAllowed.new('not ready'))
        expect do
          api.fetch('some-inventory-file', 0.1, 3)
        end.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotAllowed, 'not ready')
      end
    end

    context 'with data' do
      let(:response) { { 'result' => 'your data' } }

      it 'returns contents' do
        stubs.get('some-inventory-file') do |_env|
          [200, {}, response.to_json]
        end
        contents = api.fetch('some-inventory-file', 0.1, 3)
        expect(contents).to eq(response)
        stubs.verify_stubbed_calls
      end
    end
  end

  describe '#status' do
    let(:response) do
      {
        'entries' => %w[gas electricity],
        'resource' => '/2234567891000/',
        'responseTimestamp' => '2021-02-08T19:50:35.929Z'
      }
    end

    it 'requests correct url' do
      stubs.get('/123456789100/') do |_env|
        [200, {}, response.to_json]
      end
      resp = api.status(mpxn)
      expect(resp['entries']).to eql %w[gas electricity]
      stubs.verify_stubbed_calls
    end

    context 'with auth failure' do
      let(:response) { { "message": 'Unauthorized' } }

      it 'raises error' do
        stubs.get('/123456789100/') do |_env|
          [401, {}, response.to_json]
        end
        expect { api.status(mpxn) }.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotAuthorised, 'Unauthorized')
        stubs.verify_stubbed_calls
      end
    end

    context 'with unknown meter' do
      let(:response) do
        {
          "errors": [
            { "code": 404, "message": "No property could be found with identifier '123456789100'" }
          ]
        }
      end

      it 'raises error' do
        stubs.get('/123456789100/') do |_env|
          [404, {}, response.to_json]
        end
        expect do
          api.status(mpxn)
        end.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotFound,
                           "No property could be found with identifier '123456789100'")
        stubs.verify_stubbed_calls
      end
    end

    context 'with consent failure' do
      let(:response) do
        {
          "errors": [
            { "code": 403, "message": "You do not have a registered consent to access \u0027123456789100\u0027" }
          ]
        }
      end

      it 'raises error' do
        stubs.get('/123456789100/') do |_env|
          [403, {}, response.to_json]
        end
        expect { api.status(mpxn) }.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotAllowed)
        stubs.verify_stubbed_calls
      end
    end
  end

  describe '#get_elements' do
    let(:response) do
      {
        'entries' => [
          1,
          2
        ],
        'resource' => '1234567891001/electricity/consumption',
        'responseTimestamp' => '2021-02-23T16:36:14.801Z'
      }
    end

    it 'requests correct url' do
      stubs.get('/123456789100/electricity/consumption/') do |_env|
        [200, {}, response.to_json]
      end
      elements = api.get_elements(mpxn: mpxn, fuel_type: fuel_type)
      expect(elements['entries']).to eql [1, 2]
      stubs.verify_stubbed_calls
    end

    it 'supports other reading types' do
      stubs.get('/123456789100/electricity/production/') do |_env|
        [200, {}, response.to_json]
      end
      elements = api.get_elements(mpxn: mpxn, fuel_type: fuel_type, reading_type: 'production')
      expect(elements['entries']).to eql [1, 2]
      stubs.verify_stubbed_calls
    end
  end

  describe '#get_consumption_data' do
    let(:response) { JSON.parse(File.read('spec/fixtures/n3rgy/get_consumption_data.json')) }

    it 'requests correct url' do
      stubs.get('/123456789100/electricity/consumption/1') do |_env|
        [200, {}, response.to_json]
      end
      data = api.get_consumption_data(mpxn: mpxn, fuel_type: fuel_type)
      expect(data['resource']).to eql '/2234567891000/electricity/consumption/1'
      stubs.verify_stubbed_calls
    end

    it 'adds dates' do
      stubs.get('/123456789100/electricity/consumption/1') do |env|
        expect(env.params).to eql('start' => '202001010000', 'end' => '202001020000')
        [200, {}, response.to_json]
      end
      date = Date.parse('2020-01-01')
      data = api.get_consumption_data(mpxn: mpxn, fuel_type: fuel_type, start_date: date, end_date: date + 1)
      expect(data['resource']).to eql '/2234567891000/electricity/consumption/1'
      stubs.verify_stubbed_calls
    end
  end

  describe '#get_tariff_data' do
    let(:response) { JSON.parse(File.read('spec/fixtures/n3rgy/get_tariff_data.json')) }

    it 'requests correct url' do
      stubs.get('/123456789100/electricity/tariff/1') do |_env|
        [200, {}, response.to_json]
      end
      data = api.get_tariff_data(mpxn: mpxn, fuel_type: fuel_type)
      expect(data['resource']).to eql '/2234567891000/electricity/tariff/1'
      stubs.verify_stubbed_calls
    end
  end

  describe '#read-inventory' do
    let(:inventory_url) { 'https://read-inventory.data.n3rgy.com/files/3b80564b-fa21-451a-a8a1-2b4abb6bb8f6.json' }
    let(:response) do
      {
        'status' => 200,
        'uuid' => '3b80564b-fa21-451a-a8a1-2b4abb6bb8f6',
        'uri' => inventory_url
      }
    end

    it 'requests correct url' do
      stubs.post('/read-inventory') do |env|
        expect(env.body).to eql({
          mpxns: ['123456789100']
        }.to_json)
        [200, {}, response.to_json]
      end
      data = api.read_inventory(mpxn: mpxn)
      expect(data['uuid']).to eql '3b80564b-fa21-451a-a8a1-2b4abb6bb8f6'
      stubs.verify_stubbed_calls
    end
  end

  describe '#fetch' do
    let(:response) do
      {
        'entries' => %w[gas electricity],
        'resource' => '/2234567891000/',
        'responseTimestamp' => '2021-02-08T19:50:35.929Z'
      }
    end

    it 'requests correct url' do
      stubs.get('/123456789100') do |_env|
        [200, {}, response.to_json]
      end
      data = api.fetch('/123456789100')
      expect(data['entries']).to eql %w[gas electricity]
      stubs.verify_stubbed_calls
    end
  end

  describe '#find' do
    let(:response) do
      {
        "mpxn": '123456789100',
        "deviceType": 'ESME'
      }
    end

    it 'requests correct url' do
      stubs.get('/find-mpxn/123456789100') do |_env|
        [200, {}, response.to_json]
      end
      data = api.find('123456789100')
      expect(data['deviceType']).to eql('ESME')
      stubs.verify_stubbed_calls
    end

    it 'raise Not Found if not found' do
      stubs.get('/find-mpxn/123456789100') do |_env|
        [404, {}, 'not there']
      end
      expect { api.find(123_456_789_100) }.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotFound, 'not there')
      stubs.verify_stubbed_calls
    end
  end

  describe '#find' do
    let(:response) do
      {
        "mpxn": '123456789100',
        "deviceType": 'ESME'
      }
    end

    it 'requests correct url' do
      stubs.get('/find-mpxn/123456789100') do |_env|
        [200, {}, response.to_json]
      end
      data = api.find('123456789100')
      expect(data['deviceType']).to eql('ESME')
      stubs.verify_stubbed_calls
    end

    it 'raise Not Found if not found' do
      stubs.get('/find-mpxn/123456789100') do |_env|
        [404, {}, 'not there']
      end
      expect { api.find(123_456_789_100) }.to raise_error(MeterReadingsFeeds::N3rgyDataApi::NotFound, 'not there')
      stubs.verify_stubbed_calls
    end
  end

  describe '#list' do
    let(:response) do
      { 'startAt' => 0, 'maxResults' => 100, 'total' => 3, 'entries' => %w[1234567891000 1234567891002 1234567891008],
        'resource' => '/', 'responseTimestamp' => '2021-03-29T15:48:37.637Z' }
    end

    it 'requests correct url' do
      stubs.get('/') do |_env|
        [200, {}, response.to_json]
      end
      data = api.list
      expect(data['total']).to be(3)
      stubs.verify_stubbed_calls
    end
  end
end
