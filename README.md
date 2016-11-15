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
