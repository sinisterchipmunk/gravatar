class XMLRPC::Client
  def set_debug
    @http.set_debug_output($stderr);
  end
end
