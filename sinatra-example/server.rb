require "open-uri"

enable :sessions


helpers do
    def confirmed_mail
        session[:confirmed_mail]
    end
end

get '/' do
    # 1. LA needs to confirm Browser the login for that email, here using the js api
    erb :index
end

post '/validate' do
    # 2. Browser needs to give confirmation token to server
    begin
        # 3. Server asks LA if login really is valid
        mail = URI.parse(URI.escape("http://localhost:9292/validate?token=" + params[:token])).read
        # if we are here, the token got confirmed
        # 4. Server needs to promote user session
        session[:confirmed_mail] = mail
    rescue OpenURI::HTTPError => e
        puts "could not validate token: " + e.to_s
        status 403
    end
end