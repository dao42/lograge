module ActionCable
  module Channel
    class Base
      def perform_action(data)
        action = extract_action(data)

        if processable_action?(action)
          payload = { channel_class: self.class.name, action: action, data: data }
          ActiveSupport::Notifications.instrument('perform_action.action_cable', notification_payload(action).merge(payload)) do
            dispatch_action(action, data)
          end
        else
          logger.error "Unable to process #{action_signature(action, data)}"
        end
      end

      def subscribe_to_channel
        ActiveSupport::Notifications.instrument('subscribe.action_cable', notification_payload('subscribe')) do
          run_callbacks :subscribe do
            subscribed
          end

          reject_subscription if subscription_rejected?
          ensure_confirmation_sent
        end
      end

      def unsubscribe_from_channel
        ActiveSupport::Notifications.instrument('unsubscribe.action_cable', notification_payload('unsubscribe')) do
          run_callbacks :unsubscribe do
            unsubscribed
          end
        end
      end

      private

      def notification_payload(method_name)
        { channel_class: self.class.name, action: method_name }
      end
    end
  end
end
