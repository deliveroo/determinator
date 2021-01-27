class IndexController < ApplicationController
  def show
    is_colloquial = determinator.feature_flag_on?(:colloquial_welcome)
    emoji = determinator.which_variant(:welcome_emoji)

    message = [
      is_colloquial ? "hi world" : "hello world",
      (emoji if emoji)
    ].compact.join(" ")

    explain = "An experiment and a feature flag are being checked for the user with guid #{guid}. "
    explain += "The feature flag (colloquial_welcome) is #{is_colloquial ? 'on' : 'off'}. "
    explain += "The experiment (welcome_emoji) returned #{emoji}#{", so is omitted" unless emoji}."

    render json: { welcome: message, explanation: explain }
  end
end
