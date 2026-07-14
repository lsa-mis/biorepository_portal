require 'rails_helper'

RSpec.describe RequestMailer, type: :mailer do
  describe '#get_custom_email_messages' do
    it 'loads custom collection messages in one query' do
      collections = [
        create(:collection, division: 'Division A', admin_group: 'group-a'),
        create(:collection, division: 'Division B', admin_group: 'group-b'),
        create(:collection, division: 'Division C', admin_group: 'group-c')
      ]

      collections.each do |collection|
        create(
          :app_preference,
          collection: collection,
          name: 'custom_message_information_request',
          value: "Message for #{collection.division}"
        )
      end

      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _id, payload|
        next if payload[:cached] || payload[:name] == 'SCHEMA'

        queries << payload[:sql] if payload[:sql].match?(/FROM "app_preferences"/)
        queries << payload[:sql] if payload[:sql].match?(/FROM "collections"/)
      end

      begin
        result = described_class.new.send(
          :get_custom_email_messages,
          collections.map(&:id),
          'custom_message_information_request'
        )
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(result).to eq(
        'Division A' => 'Message for Division A',
        'Division B' => 'Message for Division B',
        'Division C' => 'Message for Division C'
      )
      expect(queries.length).to eq(1)
      expect(queries.first).to include('INNER JOIN "collections"')
    end
  end
end
