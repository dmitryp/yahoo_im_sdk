module YahooImSdk

  class HTTPartyExt
     include HTTParty

     parser(
       Proc.new do |body, format|
         Crack::JSON.parse(body)
       end
     )
  end
end