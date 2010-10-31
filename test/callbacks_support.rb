#from MongoMapper test suite
module CallbacksSupport
  def self.included base
    base.key :name, String

    [ :after_find,        :after_initialize,
      :before_validation, :after_validation,
      :before_create,     :after_create,
      :before_update,     :after_update,
      :before_save,       :after_save,
      :before_destroy,    :after_destroy
    ].each do |callback|
      base.send(callback) do
        history << callback.to_sym
      end
    end
  end

  def history
    @history ||= []
  end

  def clear_history
    embedded_associations.each { |a| self.send(a.name).each(&:clear_history) }
    @history = nil
  end
end
