 
module AbstractSyntax where

import Data.List
import qualified Data.Map as M

type NonTerminal = String
type Var = String

type ApegGrm = [ApegRule]
 

 
-- ApegRule  (Name or String) (Inherited Syntatical Parameters)
data ApegRule = ApegRule NonTerminal [(Type,Var)] [Expr] APeg deriving Show

data APeg = Lambda
         | Lit String
         | NT NonTerminal [Expr] [Expr]
         | Kle APeg
         | Not APeg
         | Seq [APeg]
         | Alt [APeg]
         | AEAttr [(Var,Expr)] -- The list of attributions of expressions to varaibales
         | Bind Var APeg
         deriving Show

data Expr = Str String 
          | EmptyMap  
          | MetaPeg MAPeg
          | MetaExp Expr 
          | EVar Var
          | ExtRule Expr Expr Expr -- ExtRule  Grammar RuleName Apeg
          | MkRule NonTerminal [(Type,Var)] [Expr] Expr
          | Mp [(String,Expr)] 
          | MapIns Expr String Expr -- Map insertion method
          | MapAcces Expr Expr         -- Map Access method
          deriving Show
          
 -- Combinators for dybamically building PEGS 
data MAPeg = MkLambda 
           | MkCal NonTerminal [Expr] [Expr]
           | MkKle Expr 
           | MkNot Expr
           | MkSeq [Expr]
           | MkAlt [Expr]
           | MkAE [(Var,Expr)] 
           deriving Show


data Type = TyStr
          | TyMetaPeg Type
          | TyMetaExp Type
          | TyLanguage -- This type is to be attributed to Grammar whose all rules are correct.
          | TyMap Type
          deriving (Show, Eq)



-- =================== AST Manipulation Utilities =================== --
                                         
fetch :: ApegGrm -> String -> ApegRule
fetch (x@(ApegRule nt _ _ _  ):xs) s
    | nt == s = x
    | otherwise = fetch xs s
    
mkAltBody :: APeg -> APeg -> APeg
mkAltBody (Alt xs) y = Alt (xs ++ [y])
mkAltBody x y = Alt [x,y]
    
grmExtRule :: ApegGrm -> NonTerminal -> APeg -> ApegGrm
grmExtRule [] _ _ = []
grmExtRule (x@(ApegRule nt inh syn body):xs) nt' newAlt 
    | nt == nt' = (ApegRule nt inh syn (mkAltBody body newAlt)):xs
    | otherwise = x: grmExtRule xs nt' newAlt
    
    
-- =================== Show Utilities =================== --

prec :: APeg -> Int
prec  Lambda = 0
prec (Lit _) = 0
prec (Kle _) = 1
prec (Not _) = 1
prec (Seq _) = 2
prec (Alt _) = 3

parensStr :: Bool -> String -> String
parensStr True s  = "(" ++ s ++ ")" 
parensStr False s = s

isPegAlt :: APeg -> Bool
isPegAlt (Alt n) = True
isPegAlt _       = False

isPegSeq :: APeg -> Bool
isPegSeq (Seq _) = True
isPegSeq _       = False

parensAssoc :: APeg -> APeg -> Bool
parensAssoc encl inner 
    | (isPegAlt encl) && (isPegSeq inner) = True
    | (isPegSeq encl) && (isPegAlt inner) = True
    | otherwise = False
    
-- instance Show APeg where
--      showsPrec d (Lit l)        = \s -> ('\'':l ++ ['\'']) ++ s
--      showsPrec d Lambda         = \s -> ("\x03BB") ++ s
--      showsPrec d (NT n xs ys)   = \s ->n ++ s
--      showsPrec d c@(Kle p)      = (parensStr (prec c > d) ).(\s -> s ++ "*").(showsPrec (prec c) p) 
--      showsPrec d c@(Not p)      = (parensStr (prec c > d) ).(showString "!").(showsPrec (prec c) p)
--      showsPrec d c@(AEAttr xs)  = (showString "{").(showsPrec (prec c) p).(showString "}")
--      showsPrec d c@(Seq xs)     = (parensStr (prec c > d) ).(foldr1 (.) (map (showsPrec (prec c)) xs)) 
--      showsPrec d c@(Alt xs)     = (parensStr (prec c > d) ).(foldr1 (\c d -> c.(showString "|").d) (map (showsPrec (prec c)) xs))
--      show p                     = showsPrec 3 p ""
