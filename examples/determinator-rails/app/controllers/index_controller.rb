class IndexController < ApplicationController
  def show
    is_colloquial = determinator.feature_flag_on?(:colloquial_welcome)
    emoji = determinator.which_variant(:welcome_emoji)

    if emoji
      # TODO: Track that this user saw a variant of this experiment
    end

    message = is_colloquial ? "hi world" : "hello world"
    message << ' ' + emoji if emoji

    render json: { welcome: message }
  end
end
