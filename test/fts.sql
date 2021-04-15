create extension if not exists rum;
create extension if not exists pg_jieba;

alter table xmh_shop.shop_goods add column tsv tsvector;
create index rumidx_shop_goods_tsv on xmh_shop.shop_goods using rum(tsv rum_tsvector_ops);

CREATE OR REPLACE FUNCTION shop_goods_tsv_trigger() RETURNS trigger AS $$
begin
      new.tsv := setweight(to_tsvector('jiebaqry', coalesce(new.goods_name,'')), 'C')
              || setweight(array_to_tsvector(regexp_split_to_array(coalesce(new.keywords,''), '\s+')), 'A')
           -- || setweight(to_tsvector('jiebaqry', coalesce(new.description,'')), 'b')
              ;
      return new;
end
$$ LANGUAGE plpgsql;

CREATE TRIGGER shop_goods_tsv_update BEFORE INSERT OR UPDATE
    ON xmh_shop.shop_goods FOR EACH ROW EXECUTE PROCEDURE shop_goods_tsv_trigger();

update xmh_shop.shop_goods set tsv = null;
-- UPDATE xmh_shop.shop_goods set tsv = setweight(to_tsvector('jiebaqry', coalesce(goods_name,'')), 'B')
--     || setweight(array_to_tsvector(regexp_split_to_array(coalesce(keywords,''), '\s+')), 'A');


-- 同义词
-- select * from ts_debug('jiebacfg', '当一个词典配置文件第一次在数据库会话中使');
-- select ts_lexize('jieba_syn1', '男式');
create text search dictionary jieba_syn (template = synonym, synonyms='jieba_synonym');
alter text search dictionary jieba_syn (synonyms='jieba_synonym');
create text search configuration my_qry (copy = jiebaqry);
alter text search configuration my_qry alter mapping for n with jieba_syn, jieba_stem;

/*
with ts as ( select to_tsquery('jiebaqry', 'hello') as q) select goods_name, keywords, tsv from ts, xmh_shop.shop_goods where tsv @@ ts.q order by tsv <=> ts.q limit 100 ;


with ts as (
  select to_tsquery('jiebaqry', 'hello') as q
) select
    ts_headline('jiebaqry', goods_name, ts.q, 'StartSel = {{, StopSel = }}') ,
    description, tsv
from ts, xmh_shop.shop_goods where tsv @@ ts.q
order by tsv <=> ts.q
--limit 100
;
*/
