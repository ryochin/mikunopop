drop table video;
create table video (
    vid char(12),

    title varchar(255),
    description varchar(255),
    length char(12),
    first_retrieve datetime,

    view_counter int(10),
    mylist_counter int(10),
    comment_num int(10),

    pnames varchar(255) ,
    tags varchar(255) ,

    count int(1) not null default 0,
    
    regist_date datetime,
    update_date datetime,
    
    PRIMARY KEY  (vid)
);
