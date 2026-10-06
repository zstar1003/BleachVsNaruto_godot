"""Parse AS3 timeline statements to a small, inspectable AST (never execute AS3)."""
import re,json
TOKEN=re.compile(r'\s+|//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|0[xX][0-9a-fA-F]+|(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?|[A-Za-z_$][\w$]*|===|!==|==|!=|<=|>=|&&|\|\||\+\+|--|\+=|-=|\*=|/=|<<|>>|[^\s]',re.S)
class ParseError(ValueError):pass
class Parser:
 def __init__(self,text):self.tokens=[m[0] for m in TOKEN.finditer(text) if not m[0].isspace() and not m[0].startswith(('//','/*'))];self.i=0
 def peek(self):return self.tokens[self.i] if self.i<len(self.tokens) else ''
 def take(self,expected=None):
  s=self.peek()
  if not s or expected is not None and s!=expected:raise ParseError(f'Expected {expected}, got {s!r}, near {self.tokens[max(0,self.i-5):self.i+8]}')
  self.i+=1;return s
 def eat(self,s):
  if self.peek()==s:self.i+=1;return True
  return False
 def statements(self,closing=''):
  out=[]
  while self.peek() and self.peek()!=closing:out.append(self.statement())
  return out
 def block(self):
  if self.eat('{'):out=self.statements('}');self.take('}');return out
  return [self.statement()]
 def statement(self):
  if self.eat(';'):return ['nop']
  if self.eat('continue'):self.eat(';');return ['continue']
  if self.eat('if'):
   self.take('(');test=self.expr();self.take(')');yes=self.block();no=self.block() if self.eat('else') else []
   return ['if',test,yes,no]
  if self.eat('for'):
   self.take('each');self.take('(');target=self.expr();self.take('in');array=self.expr();self.take(')');return ['foreach',target,array,self.block()]
  if self.eat('switch'):
   self.take('(');test=self.expr();self.take(')');self.take('{');cases=[]
   while self.peek()!='}':
    default=self.eat('default')
    if not default:self.take('case')
    value=['lit',None] if default else self.expr();self.take(':');body=[]
    while self.peek() not in ('case','default','}'):
     if self.eat('break'):self.eat(';');break
     body.append(self.statement())
    cases.append([value,body,default])
   self.take('}');return ['switch',test,cases]
  if self.eat('return'):
   v=['lit',None] if self.peek() in (';','}') else self.expr();self.eat(';');return ['return',v]
  if self.peek() in ('var','const'):
   self.take();name=self.take()
   if self.eat(':'):
    while self.peek() not in ('=',';',')',',','') : self.take()
   v=self.expr() if self.eat('=') else ['lit',None];self.eat(';');return ['set',['var',name],v]
  if self.peek() in ('while','for','switch','try','throw','function'):raise ParseError('Unsupported statement '+self.peek())
  expr=self.expr();self.eat(';');return ['eval',expr]
 precedence={'=':1,'+=':1,'-=':1,'*=':1,'/=':1,'||':3,'&&':4,'==':5,'!=':5,'===':5,'!==':5,'<':6,'>':6,'<=':6,'>=':6,'is':6,'as':6,'+':8,'-':8,'*':9,'/':9,'%':9}
 def expr(self,minp=0):
  t=self.take()
  if t in ('!','-','+','~'):left=['un',t,self.expr(10)]
  elif t=='(':
   left=self.expr();self.take(')')
  elif t=='[':
   items=[]
   while self.peek()!=']':
    items.append(self.expr());
    if not self.eat(','):break
   self.take(']');left=['array',items]
  elif t=='{':
   pairs=[]
   while self.peek()!='}':
    key=self.take();key=json.loads(key) if key.startswith('"') else key;self.take(':');pairs.append([key,self.expr()])
    if not self.eat(','):break
   self.take('}');left=['object',pairs]
  elif t.startswith(('"',"'")):left=['lit',json.loads(t) if t[0]=='"' else t[1:-1]]
  elif t.lower().startswith('0x'):left=['lit',int(t,16)]
  elif re.match(r'^\d|^\.\d',t):left=['lit',float(t) if any(x in t for x in '.eE') else int(t)]
  elif t in ('true','false','null','undefined'):left=['lit',{'true':True,'false':False,'null':None,'undefined':None}[t]]
  elif t=='new':left=['new',self.expr(11)]
  else:left=['var',t]
  while True:
   t=self.peek()
   if t=='.':self.take();left=['get',left,self.take()];continue
   if t=='[':self.take();key=self.expr();self.take(']');left=['index',left,key];continue
   if t=='(':
    self.take();args=[]
    while self.peek()!=')':
     args.append(self.expr())
     if not self.eat(','):break
    self.take(')');left=['call',left,args];continue
   if t in ('++','--'):left=['post',self.take(),left];continue
   if t=='?' and minp<=2:
    self.take();yes=self.expr();self.take(':');no=self.expr(2);left=['ternary',left,yes,no];continue
   p=self.precedence.get(t,-1)
   if p<minp:break
   self.take();right=self.expr(p if p==1 else p+1);left=['assign' if p==1 else 'bin',t,left,right]
  return left

def parse(text):
 p=Parser(text);out=p.statements()
 if p.peek():raise ParseError('Unconsumed '+p.peek())
 return out
