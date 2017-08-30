class NullCache
  def fetch(name)
    yield
  end
end
