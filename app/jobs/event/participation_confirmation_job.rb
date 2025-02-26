# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationConfirmationJob < BaseJob

  self.parameters = [:participation_id, :locale]

  def initialize(participation)
    super()
    @participation_id = participation.id
  end

  def perform
    return unless participation # may have been deleted again

    set_locale
    send_confirmation
    send_notification
    send_approval
  end

  private

  def send_confirmation
    return unless participation.person.valid_email?

    Event::ParticipationMailer.confirmation(participation).deliver_now
  end

  def send_notification
    return unless notify_contact?(participation.event)

    Event::ParticipationMailer
      .notify_contact(participation, participation.event.contact).deliver_now
  end

  def send_approval
    if participation.event.requires_approval?
      recipients = approvers
      if recipients.present?
        Event::ParticipationMailer.approval(participation, recipients).deliver_now
      end
    end
  end

  def approvers
    approver_types = Role.types_with_permission(:approve_applications).collect(&:sti_name)
    layer_ids = participation.person.groups.without_deleted
                             .merge(Person.members)
                             .collect(&:layer_group_id)
                             .uniq
    Person.only_public_data
          .joins(roles: :group)
          .where(roles: { type: approver_types, deleted_at: nil },
                 groups: { layer_group_id: layer_ids })
          .distinct
  end

  def participation
    @participation ||= Event::Participation.find_by(id: @participation_id)
  end

  def notify_contact?(event)
    event.notify_contact_on_participations? && event.contact.present?
  end
end
