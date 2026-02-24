class Api::DocsController < ApplicationController
  before_action :require_admin!, -> { @no_container = true }

  def index; end

  def users; end

  def quizzes; end

  def languages; end

  def authentication; end

  def general_errors; end

  def bugs; end
end
