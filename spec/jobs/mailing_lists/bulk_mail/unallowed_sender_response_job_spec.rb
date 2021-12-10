# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.


require 'spec_helper'

describe MailingLists::BulkMail::UnallowedSenderResponseJob do
  include MailingLists::ImapMailsHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:imap_mail)       { built_imap_mail(plain_body: true) }
  let(:mail_log) { MailLog.new(mail_hash: imap_mail.hash, status: :retrieved, mail_from: imap_mail.sender_email) }
  let(:bulk_mail) { Message::BulkMail.new(subject: imap_mail.subject, state: :pending, raw_source: imap_mail.raw_source, mailing_list: mailing_list, mail_log: mail_log) }

  context 'send unallowed message to sender' do
    subject { described_class.new(bulk_mail) }

    it 'replies' do
      Settings.email.retriever.config = Config::Options.new(address: 'localhost')

      subject.perform

      expect(last_email.to).to eq(["from@example.com"])
      expect(last_email.from).to eq(["noreply"])
      expect(last_email.subject).to eq("RE: Testflight from 24.4.2021")
      expect(last_email.body.decoded).to eq("Du bist nicht berechtigt, auf die Liste leaders@localhost zu schreiben.")
    end
  end
end
