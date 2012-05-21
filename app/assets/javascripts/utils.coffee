$ ->
  module 'rm'

  rm.Utils =
    hashToArray: (hash) ->
      return result = for key, value of hash
        { key: key, value: value }
