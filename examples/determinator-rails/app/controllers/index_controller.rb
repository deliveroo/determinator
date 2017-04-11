class IndexController < ApplicationController
  def show
    if determinator.feature_flag_on?(:colloquial_welcome)
      render json: { welcome: 'hi world' }
    else
      render json: { welcome: 'hello world' }
    end
  end
end
