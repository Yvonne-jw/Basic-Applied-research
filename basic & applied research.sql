/****** Script for basic and applied research

--data fomr Boyack:Rlev_out

******/


---------------------------------------main field-------------------------------
--match with openalex
drop table if exists #openalex_abstract_title
select distinct a.euid,b.work_id,f.title as eurekalert_title, a.correct_doi, e.content, c.abstract, d.title as paper_title
into #openalex_abstract_title
from [userdb_zhangz10].[dbo].[eurekalert_metadata_doi] a
inner join openalex_2023feb.dbo.work b
on a.correct_doi = b.doi
inner join projectdb_eurekalert_2023mar.dbo.EurekAlert_metadata f
on f.euid = a.euid
inner join openalex_2023feb.dbo.work_abstract c
on b.work_id  = c.work_id 
inner join openalex_2023feb.dbo.work_title d
on b.work_id  =d.work_id
inner join projectdb_eurekalert_2023mar.dbo.EurekAlert_fulltext e
on e.euid = a.euid
where f.title is not null and len(e.content) >200 and c.abstract is not null
--with title and abstract 122530;00:31
-- delete some duplicate 122526
--into openalex_abstract_title

--euid with LR field with openalex
  drop table if exists eu_openalex_LR
  select distinct a.*,c.LR_main_field_id,d.LR_main_field
  into eu_openalex_LR
  from #openalex_abstract_title a
  inner join [openalex_2023feb_classification].[dbo].[clustering] b
  on a.work_id = b.work_id
  inner join [openalex_2023feb_classification].[dbo].[micro_cluster_LR_main_field] c
  on b.[micro_cluster_id] = c.[micro_cluster_id]
  inner join [openalex_2023feb_classification].[dbo].LR_main_field d
  on c.LR_main_field_id = d.LR_main_field_id
  where c.[is_primary_LR_main_field] = 1
  --119328,00:11

select count(*)
from Rlev_out a
inner join eu_openalex_LR b
on a.euid = b.euid
inner join projectdb_eurekalert_2023mar.dbo.EurekAlert_metadata c
on a.euid = c.euid
where year(c.post_time)<2023
group by b.LR_main_field

-------------------top journal--------------------
drop table if exists #RL_LR
select a.EUID,a.DOI,a.RL
       ,b.LR_main_field,c.institution
	   ,year(c.post_time) as post_time
	   ,e.source as journal,c.journal as eu_joural
into #RL_LR
from Rlev_out a
inner join eu_openalex_LR b
on a.euid = b.euid
inner join projectdb_eurekalert_2023mar.dbo.EurekAlert_metadata c
on a.euid = c.euid
inner join openalex_2023nov.dbo.work d
on d.doi = a.DOI
inner join openalex_2023nov.dbo.source e
on e.source_id = d.source_id
where year(c.post_time)<2023
-- 116810;00:08



select top(15) journal 
from #RL_LR
group by journal
order by count(*) desc

select  journal,RL,LR_main_field,count(*) as count_number
from #RL_LR
where journal in (select top(15) journal 
from #RL_LR
group by journal
order by count(*) desc)
group by RL,journal,LR_main_field



-------top institute------
drop table if exists #RL_institution
select a.EUID,a.DOI,a.RL
       ,b.LR_main_field,c.institution
	   ,f.institution as author_institution
into  #RL_institution
from Rlev_out a
inner join [userdb_zhangz10].[dbo].[eu_openalex_LR] b
on a.euid = b.euid
inner join projectdb_eurekalert_2023mar.dbo.EurekAlert_metadata c
on a.euid = c.euid
inner join [openalex_2023nov].[dbo].[work_institution] e
on e.work_id = b.work_id
inner join openalex_2023nov.dbo.institution f
on f.institution_id = e.institution_id
where year(c.post_time)<2023
--582208;00:34

select institution,RL,LR_main_field,count(*) as number
from #RL_institution
where institution in (select top(15) institution
from #RL_institution
group by institution
order by count(*) desc)
group by institution,RL,LR_main_field

----top organization---
select author_institution,RL,LR_main_field,count(*) as number
from #RL_institution
where author_institution in (select top(15) author_institution
from #RL_institution
group by author_institution
order by count(*) desc)
group by author_institution,RL,LR_main_field



----------------keywords map------------
drop table if exists #eu_keywords
SELECT distinct a.euid,c.keyword,d.LR_main_field
into #eu_keywords
from Rlev_out a
inner join projectdb_eurekalert_2023mar.dbo.EurekAlert_keyword b
on a.euid = b.euid
inner join projectdb_eurekalert_2023mar.dbo.keyword_id c
on b.keyword_id = c.keyword_id
inner join [userdb_zhangz10].[dbo].[eu_openalex_LR] d
on a.euid = d.euid

SELECT 
    t.euid,
	a.RL,
	a.RL_number,
    STUFF((
        SELECT '; ' + CAST(keyword AS VARCHAR(MAX))
        FROM #eu_keywords
        WHERE euid = t.euid
        FOR XML PATH(''), TYPE
    ).value('.', 'VARCHAR(MAX)'), 1, 2, '') AS keywords
	,t.LR_main_field
FROM #eu_keywords t
inner join Rlev_out a
on t.euid = a.euid
GROUP BY t.euid,a.RL,t.LR_main_field,a.RL_number;

-------------------fulltext & abstract-------------
select a.euid,a.RLEV,b.content,b.abstract
from Rlev_out a
inner join eu_openalex_LR b
on a.euid = b.euid

----------------divided into basic and apply----------------
  ALTER TABLE Rlev_out ADD RL_number int;
  ALTER TABLE Rlev_out ADD RL nvarchar(50);

  update Rlev_out
  set RL_number = 1
      ,RL = 'basic'
  where RLEV =4  

  update Rlev_out
  set RL_number = 2
      ,RL = 'apply'
  where RLEV =2 or RLEV = 3 or RLEV =1
----------------------------------------