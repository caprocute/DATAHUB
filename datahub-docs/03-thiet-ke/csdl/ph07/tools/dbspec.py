import subprocess, json, sys
S=sys.argv[1]
def q(sql):
    r=subprocess.run(['psql','-h',S+'/pg','-p','55432','-U','postgres','-d','datahub','-At','-c',sql],capture_output=True,text=True,check=True)
    return r.stdout.strip()
tabs=json.loads(q("""select json_agg(json_build_object('t',c.relname,'cm',obj_description(c.oid),'part',c.relkind='p') order by c.relname)
 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='ph07_rdm' and c.relkind in ('r','p') and not c.relispartition"""))
cols=json.loads(q("""select json_agg(json_build_object('t',c.relname,'n',a.attname,'ty',format_type(a.atttypid,a.atttypmod),'nn',a.attnotnull,
 'df',pg_get_expr(d.adbin,d.adrelid),'gen',a.attgenerated<>'','cm',col_description(c.oid,a.attnum)) order by c.relname,a.attnum)
 from pg_attribute a join pg_class c on c.oid=a.attrelid join pg_namespace n on n.oid=c.relnamespace left join pg_attrdef d on d.adrelid=a.attrelid and d.adnum=a.attnum
 where n.nspname='ph07_rdm' and c.relkind in ('r','p') and not c.relispartition and a.attnum>0 and not a.attisdropped"""))
cons=json.loads(q("""select json_agg(json_build_object('t',c.relname,'n',k.conname,'ty',k.contype,'def',pg_get_constraintdef(k.oid)) order by c.relname,k.contype,k.conname)
 from pg_constraint k join pg_class c on c.oid=k.conrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='ph07_rdm' and not c.relispartition"""))
idx=json.loads(q("""select json_agg(json_build_object('t',tablename,'n',indexname,'def',indexdef) order by tablename,indexname) from pg_indexes i
 join pg_class c on c.relname=i.tablename and c.relnamespace='ph07_rdm'::regnamespace where schemaname='ph07_rdm' and not c.relispartition"""))
pol=json.loads(q("""select json_agg(json_build_object('t',tablename,'n',policyname,'cmd',cmd) order by tablename,policyname) from pg_policies where schemaname='ph07_rdm'"""))
json.dump({'tabs':tabs,'cols':cols,'cons':cons,'idx':idx,'pol':pol or []},open(S+'/dbspec.json','w'),ensure_ascii=False)
print(len(tabs),len(cols),len(cons),len(idx),len(pol or []))
