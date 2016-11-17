# controller/user.rb

require 'hints'

# Description:
# At very begin request will be hooked by "__rootscope"
# for each fucntion defined here there's a default route:
# def auth(uid, upass);end
# => post: /user/auth
#
# def info(uid);end
# => get: /user/info
#
# def create(uid, upass, roles);end
# => put: /user/create
#
# parameters in each function will be verified from http request,
# if no match parameters were given in the request(neither query sting nor in reqeust body)
# then will get a failed response.

class User
  include Hint

  #[:filter]
  def __rootscope
    unless request.path == '/user/auth' then
        unless token = request.env["HTTP_AUTH_TOKEN"] then
          halt 401
        else
          unless Service::System.validate_fingerprint(token, request.user_agent << request.ip)
            halt 401
          end
        end
    end
  end

  #[:rpost]
  def auth(uid, upass)
      if user = Service::User.get(uid) then
          if Service::User.auth(uid, upass) then
              token = Service::System.newtoken(request.user_agent << request.ip)
              return Result.Success do
                {token: token}
              end
          else
              return Result.Fail
          end
      else
          return Result.Fail
      end
  end

  #[:rget]
  def info(uid)
      if user = Service::User.get(uid) then
        Result.Success do
          {uid: uid, roles: user.roles, last_update_date: user.last_update_date}
        end
      else
        return Result.Fail
      end
  end

  #[:rput]
  def create(uid, upass, roles)
      return Result.Fail("User already existed") if Service::User.get(uid)
      if Service::User.create({uid: uid, upass: upass}) then
          return Result.Success
      else
          return Result.Fail
      end
  end

end

=begin
# Above code equals to following sanatra dsl

require 'sinatra'
require_relative 'controller/user.rb'

@controller_user = User.new
before do
  @controller_user.__rootscope
end

post 'user/auth' do
  param_check('uid', 'upass')
  @controller_user.auth(params['uid'], params['upass'])
end

get 'user/info' do
  param_check('uid')
  @controller_user.info(params['uid'])
end

put 'user/create' do
  param_check('uid', 'upass')
  @controller_user.create(params['uid'], params['upass'])
end

=end
