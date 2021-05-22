with recursive bm as (
    select array['headquarters'] as d_name, 0::numeric as id, 0::numeric as parentid, 0::numeric as "isDelete", '1000' as "Factory_Id"
union all
    select array_append(bm.d_name, next.d_name), next.id, next.parentid, next."isDelete", next."Factory_Id"
    from bm join xmhshop20141223.hr_department as next on bm.id = next.parentid
    where next."isDelete" = 0 and next."Factory_Id" = '1000'
)
select case when count(d_name[array_length(d_name,1)]) over (partition by d_name[array_length(d_name,1)]) > 1
                   then array_to_string(d_name, ' -> ')
              else d_name[array_length(d_name,1)]
         end ,
         id
from bm order by bm.d_name
;
