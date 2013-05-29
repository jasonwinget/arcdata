class Scheduler::SwapMailer < ActionMailer::Base
  default from: "DAT Scheduling <scheduling@arcbadat.com>"

  def swap_invite(shift, person)
    @person = person
    @recipient = person
    @shift = shift
    mail to: person.email, subject: swap_invite_subject
  end

  def swap_available(shift, recipient)
    @person = nil
    @recipient = recipient
    @shift = shift
    mail to: recipient.email, subject: swap_invite_subject, template_name: 'swap_invite'
  end

  def swap_request_notify(shift_assignment)
    people = Roster::Person.in_county(shift_assignment.shift.county).with_position(shift_assignment.shift.positions).joins(:notification_setting).where{notification_setting.email_swap_requested eq true}
  end

  def swap_confirmed(old_shift, new_shift, recipients = nil)
    @from = old_shift
    @to = new_shift

    subject = "Shift Swap Confirmed for #{new_shift.date.to_s :dow_short} #{new_shift.shift.shift_group.name} #{new_shift.shift.name}"

    recipients ||= [@from.person.email, @to.person.email]

    mail to: recipients, subject: subject
  end

  private

  def swap_invite_subject
    subject = "Shift Swap Requested for #{@shift.date.to_s :dow_short} #{@shift.shift.shift_group.name} #{@shift.shift.name}"
  end
end
