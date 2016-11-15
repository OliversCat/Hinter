require 'hintrb'

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
