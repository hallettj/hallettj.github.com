SyntaxHighlighter.brushes.Haskell = function()
{
    var keywords = 'as case class of data default deriving do forall foreign ' +
                   'hiding if then else import infix infixl infixr instance ' +
                   'let in mdo module newtype qualified type where ';
    var datatypes = 'Char String Bool Num Int Integer Float Eq Ord Read ' +
                    'Integral Fractional';
    var special = 'True False otherwise not';

    this.regexList = [
        { regex: /--(.*)$/gm,                                      css: 'comments' },
        { regex: SyntaxHighlighter.regexLib.singleQuotedString,	   css: 'string' },
        { regex: new RegExp(this.getKeywords(keywords), 'gm'),     css: 'keyword' },
        { regex: new RegExp(this.getKeywords(datatypes), 'gm'),    css: 'color1' },
        { regex: new RegExp(this.getKeywords(special), 'gm'),      css: 'color2' },
    ];
}

SyntaxHighlighter.brushes.Haskell.prototype = new SyntaxHighlighter.Highlighter();
SyntaxHighlighter.brushes.Haskell.aliases = ['haskell', 'hs'];