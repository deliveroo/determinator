class IndexController < ApplicationController
  def show
    is_colloquial = determinator.feature_flag_on?(:colloquial_welcome)
    emoji = determinator.which_variant(:welcome_emoji)

    message = [
      is_colloquial ? "hi world" : "hello world",
      emoji
    ].compact.join(" ")

    render json: { welcome: message }
  end
end
