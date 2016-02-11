require "open-uri"
require 'json/jwt'

enable :sessions
confirmations = {}
ownUrl = "http://localhost:9293"
laUrl = "http://localhost:9292/"

helpers do
    def confirmed_mail
        session[:confirmed_mail]
    end
end

get '/' do
    # 1. LA needs to confirm Browser the login for that email, here using the js api
    erb :index
end


get '/confirm' do
    mail = confirmations.delete(params[:session_id])
    if mail
        session[:confirmed_mail] = mail
        return ""
    end
    status 403
end

# LA posts the auth token here after mail confirmation is done
post '/la_validate' do
    
    # 2. Browser needs to give confirmation token to server
    begin
        
        token = params[:id_token]
        
        # 3. Server checks signature
        # for that, fetch the public key from the LA instance (concept: Only do that for trusted instances and cache the key)
        public_key_pem = URI.parse(URI.escape("http://localhost:9292/public_key")).read
        public_key = OpenSSL::PKey::EC.new(public_key_pem)
        
        id_token = JSON::JWT.decode params[:id_token], public_key
        # 4. Needs to make sure token is still valid
        if (id_token[:iss] == laURL &&       #LA url
            id_token[:aud] == ownUrl &&        
            # id_token[:sub].present? &&  TODO: Decide whether we really can skip these two tests
            # id_token[:nonce] == expected_nonce &&
            id_token[:exp] > Time.now.to_i)
                confirmations[id_token[:nonce]] = id_token[:sub]
                return ""
        end
        
    rescue OpenURI::HTTPError => e
        puts "could not validate token: " + e.to_s
    end
    status 403
end