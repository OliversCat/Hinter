# Hints
A light and sweet MVC plugin for Sinatra. (90%)

## Description
The Hints is an easy way of MVC in Sinatra, just add a notation to an existing function and then it becomes a http request handler immediately and naturally associated with an access endpoint.

Advantage of Hints:
- Easy to understand and implement.
- 0 cost to modify an existing class to a Controller.
- 0 Configuration. Functions in the controller class can be exposed as a web access endpoint by just adding a notation.
- Flexible notation.
- No extra performance lose. Hints runs only when sinatra startup then sinatra in charge of everything.

## Quick Start
#### [Installation]
```bash
gem install hints
```

#### [Getting Start]
**"hints_setup"** need to be called to initialize hints environment.
```ruby
hints_setup(out:STDOUT, err:STDERR}
```

#### [Details]
In all examples below we assume there's a class User and there are several functions defined in it to create, query and login a user.

###### General
Make a class be a Hints Controller
```ruby
class User
  include Hints
  ...
end
```

###### Request Handler
Add a notation #[:http_verbs] above a function, then it's a handler.
Supported verbs: put, get, post, delete, patch, link
(there's a special edition of restful handler for each verb, just add 'r' ahead.)

```ruby
#[:rget]
def info(uid)
  ...
end
```

###### Access Endpoint
You can add [:endpoint] above a function to set the access endpoint.
By default, Hints will generate endpoint for each handler if it is not set explicitly.

The format of endpoint:
http(s)://localhost/**controller**/**handler**

```ruby
default endpoint: "http://localhost/user/create"
#[:rput]
def create(uid, upass)
  ...
end


customize endpoint: "http://localhost/user/new"
#[:endpoint new]
#[:rput]
def create(uid, upass)
  ...
end
```

###### Filter

###### Parameters Validation
