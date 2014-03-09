module.exports = class Utility
    @createNode: (string) ->
        tempElem = document.createElement('div')
        tempElem.innerHTML = string
        tempElem.childNodes[0]