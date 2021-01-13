# Hints
A light and sweet MVC plugin for Sinatra.

It's a Lab work to explore Sinatra features, for study and fun. :)


## Description
The Hints is an easy way of MVC in Sinatra, just add a annotation to an existing function and then it becomes a http request handler immediately and naturally associated with an access endpoint.

Advantage of Hints:
- Easy to understand and implement.
- 0 cost to modify an existing class to a Controller.
- 0 Configuration. Functions in the controller class can be exposed as a web access endpoint by just adding an annotation.
- No extra performance lose. Hints runs only when sinatra startup then sinatra in charge of everything.
- Sinatra DSLs are supported.

## Quick Start
#### [Installation]
```bash
gem install hints  #(not ready)
```

#### [Getting Start]
At the very beginning, **"hints_setup"** need to be called to initialize hints environment.
```ruby
hints_setup(out:STDOUT, err:STDERR, working_dir:'controller')
# All parameters are optional, the values in this example are just the default value.

```
| param | deault value | description |
|-------|--------------|-------------|
| out | STDOUT | set standard output stream |
| err | STDERR | set standard err stream |
| working_dir | controller | set Hints root directory (web_project_folder/controller) |

Default file structure of a Hints project:
```bash
tree
  <web_project_folder>
        |- controller # hints root
              |- user.rb
              |- article.rb
              |- comment.rb
              |- dashboard.rb
              |- ...

# you can set working_dir to customize the hints root
```
#### [Details]
In all examples below we assume there's a class User and there are several functions defined in it to create, query and login a user.

###### General
Make a class be a Hints Controller
```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint
  ...
end
```

###### Request Handler
Add an annotation **#[:verbs]** above a function, then it's a handler.<br/>
Supported verbs: **put, get, post, delete, patch, link, options** <br/>
(There's a special edition of restful handler for each verb, just add **'r'** ahead. <br/>Restful handler will force to use json in both request and respone header:  headers['Content-Type'] = 'json')

```ruby
#[:rget]
def info(uid)
  ... # sinatra DSLs are supported, you can use: halt, params, redirect, etc.
end
```

###### Access Endpoint
You can add [:endpoint] above a function to set the access endpoint.
By default, Hints will generate endpoint for each handler if it is not set explicitly.

The format of endpoint:
http(s)://localhost/**controller**/**handler**

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint

  #=> default endpoint = "http://localhost/user/create"

  #[:rput]
  def create(uid, upass)
    ...
  end


  #=> customize endpoint = "http://localhost/user/login"

  #[:endpoint login]
  #[:rpost]
  def auth(uid)
    ...
  end
end
```

Name Convention:

|source file | class | handler | endpoint|
|------------|-------|---------|---------|
|user.rb | User | create |  /user/create
|user_service.rb | UserService | auth | /user/service/atuh|

```ruby
# <web_project_folder>/controller/user_service.rb
class UserSrevice
  include Hint
  #[:rpost]
  def auth(uid, upass); end
end

endpoint = "http://localhost/user/service/auth"
source_file = user_service.rb
```


###### Filter
Sinatra filters are also supported by annotation but with limitations.

The following three situations are supported.
- Filter on handler: <br/>Add annotation #[:filter] on the function with same name of a handler and add "_"  ahead or behind.

Add "\_" ahead will make it a "Before" filter.<br/>
Add "\_" behind will make it a "After" filter.

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint

  #[:filter]
  def _create
    ...
  end

  #[:rput]
  def create(uid, upass)
    ...
  end

  #[:filter]
  def create_
    ...
  end
end

# http(s)://localhost/user/create
# => before filter
# => call User#create
# => after filter
```
- Class scope filter:<br/>
Filter works before/after all handlers(in one same controller) call.

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint
  #[:filter]
  def __scope
    ...
  end

  #[:filter]
  def scope__
    ...
  end
end

# http(s)://localhost/user/*
# => before filter
# => call any of User handlers
# => after filter
```

- Root scope filter:<br/>
Filter works before/after all handlers(in all controllers) call.

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint
  #[:filter]
  def __rootscope
    ...
  end

  #[:filter]
  def rootscope__
    ...
  end
end

# http(s)://localhost/*
# => before filter
# => call any handler
# => after filter
```
###### Parameters Validation
Hints will help to verify parameters for each handler to ensure necessary info were provided when calling.<br/>
Hints support parameters from either query string or request body

For example, there's User class with handler 'create', and this handler requires parameters: uid and pass. <br/>
A qualified http request would be: <br/>

```javascript
// url => http(s)://localhost/user/auth
// action => post
// request body =>
{
    "uid":"admin",
    "upass":"Password1!"
}
```

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint
  #[:rpost]
  def auth(uid, upass);  end
end

```

If it's a get request then a qualified http request would be: <br/>
http(s)://localhost/user/info?uid=oliver

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint
  #[:rget]
  def info(uid);  end
end

```

###### Conditions
Conditions are also supported.

```ruby
# <web_project_folder>/controller/user.rb
class User
  include Hint

  #[:conditions :agent => /Songbird (\d\.\d)[\d\/]*?/]
  #[:rget]
  def info(uid);  end
end


# Equals to:
get '/user/info', :agent => /Songbird (\d\.\d)[\d\/]*?/ do
  ...
end
```


<br/>
Any questions or suggestions are welcome, you can reach me at: nemo1023#gmail.com
