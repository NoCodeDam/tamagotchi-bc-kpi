"""Evaluate only our own small AL minute/care procedures with synthetic values.

Not a BC runtime, and never reads or executes a ROM or downloaded source.
The helper adapters model date/character configuration; core transitions are
parsed from the exact AL shipped in the app.
"""
from pathlib import Path
import re
from al_subset import ALParser,SyntheticAL
ROOT=Path(__file__).resolve().parents[1]

class SyntheticLife(SyntheticAL):
    def __init__(self):
        self.source=(ROOT/'src/TamaLife.Codeunit.al').read_text()
        header=self.source[:self.source.index('    procedure Initialize')]
        self.values={m[1].lower():False if m[2]=='Boolean' else 0 for m in re.finditer(r'(\w+): (Integer|Boolean);',header)}
        self.values.update(hunger=4,happy=4,lightson=True,randomstate=173,clockorigin=12*60)
        self.procedures={}
        for name in ['MinuteCore','CareCore','CareMiss','HeartDrop','StartSick','Kill']:
            start=self.source.index('    local procedure '+name+'(')
            body=self.source.index('    begin',start)
            stop=self.source.index('\n    local procedure ',body)
            text=re.sub(r'//[^\n]*','',self.source[body:stop]).strip()
            parser=ALParser(text);statements=parser.block();parser.pop(';')
            assert parser.index==len(parser.tokens),(name,parser.peek())
            self.procedures[name.lower()]=statements
        rules=(ROOT/'src/TamaRules.Codeunit.al').read_text();self.stats={}
        for m in re.finditer(r'^\s*(\d+(?:,\s*\d+)*): (.*SetStats\([^\n]+)$',rules,re.M):
            ids=[int(v) for v in m[1].split(',')]
            base=[int(v) for v in re.search(r'SetStats\((\d+), (\d+), (\d+), (\d+), (\d+),',m[2]).groups()]
            row=dict(zip(['basehunger','basehappy','sickinterval','evolutioninterval','minweight'],base))
            row.update(wakehour=9,bedhour=22,shots=2,discipline=0,callevery=7)
            for key,value in re.findall(r'(WakeHour|BedHour|Shots|Discipline|CallEvery) := (-?\d+)',m[2]):row[key.lower()]=int(value)
            for id in ids:self.stats[id]=row
        assert set(self.stats)==set(range(13))
        self.configure(0)

    def configure(self,id):
        v=self.values;v.update(self.stats[id]);v['characterid']=id
        v['weight']=max(v['weight'],v['minweight'])
        for key in ['stageawake','hungerelapsed','happyelapsed','sickcount','sicktime','medicinegiven','hungercall','happycall','disciplinecall','heartdrops','healthyagesteps','adultmisses']:v[key]=0
        v['stagestartedminute']=v['minutes'];v['sick']=False;v['sickleft']=v['sickinterval'];v['poopleft']=15

    def call(self,name,args):
        if name=='syncbcclock':return None  # BC time-zone API is covered by AL tests.
        if name in self.procedures:
            if name=='carecore':self.values['action']=args[0]
            self.run_statements(self.procedures[name]);return None
        if name=='min':return min(args)
        if name=='max':return max(args)
        if name=='configure':self.configure(args[0]);return None
        if name=='setsleep':
            v=self.values;before=v['sleeping'];hour=((v['minutes']-v['clockbaseminute']+v['clockorigin'])%1440)//60
            v['sleeping']=(40<=v['minutes']-v['stagestartedminute']<45) if v['characterid']==1 else hour>=v['bedhour'] or hour<v['wakehour']
            if v['sleeping'] and not before:v['lightcall']=15
            if not v['sleeping'] and before:
                v['age']+=1;v['lightson']=True;v['lightcall']=0
            return None
        if name=='checkevolution':
            v=self.values;id=v['characterid']
            if 0<id<5 and v['stageawake']>=v['evolutioninterval']:
                if id==1:self.configure(2)
                elif id==2:
                    v['typetwo']=v['disciplinemisses']>=3;self.configure(3 if v['caremisses']<3 else 4)
                    if not v['typetwo']:v['discipline']=50
                else:self.configure(5 if v['caremisses']<3 and v['disciplinemisses']==0 and not v['typetwo'] else 9)
            return None
        if name=='playgame':
            v=self.values;wins=0;threshold={7:5,8:11}.get(v['characterid'],8)
            for _ in range(5):
                v['randomstate']=(v['randomstate']*25173+13849)%32749;wins+=v['randomstate']%16<threshold
            if wins>=3:v['happy']=min(4,v['happy']+1);v['happycall']=0
            v['weight']=max(v['minweight'],v['weight']-1);return None
        raise ValueError('Unapproved life helper '+name)

    def advance(self,target):
        while self.values['minutes']<target and self.values['characterid']!=12:self.call('minutecore',[])
        if self.values['characterid']==12:self.values['minutes']=target

    def care(self,action):
        self.call('carecore',[action]);return self.values['successful']
