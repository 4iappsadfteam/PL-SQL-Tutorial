create or replace package body xxfnd_util_pkg 
is

    FUNCTION get_segment_value (
        p_segment_column   IN VARCHAR2,
        p_segment_value    IN VARCHAR2
    ) RETURN VARCHAR2 IS

        CURSOR c1 IS SELECT
            seq_number,
            segment_column,
            src_table,
            src_column,
            src_disp_column,
            src_lookup_type
                     FROM
            xxfnd_data_security
                     WHERE
            segment_column = p_segment_column
        ORDER BY
            seq_number;

        c1_rec     c1%rowtype;
        l_sql      VARCHAR2(2000) := NULL;
        l_output   VARCHAR2(2000) := NULL;
    BEGIN
        OPEN c1;
        FETCH c1 INTO c1_rec;
        IF
            c1%notfound
        THEN
            CLOSE c1;
            RETURN l_output;
        ELSE
            l_sql := 'select '
                     || c1_rec.src_disp_column
                     || ' from '
                     || c1_rec.src_table
                     || ' where 1 = 1 '
                     || ' and '
                     || c1_rec.src_column
                     || ' = '
                     || ''''
                     || p_segment_value
                     || '''';

            dbms_output.put_line('source table : ' || c1_rec.src_table);
            IF
                c1_rec.src_table = 'XXFND_LOOKUP_VALUES'
            THEN
                l_sql := l_sql
                         || ' and lookup_type_id = ( select lookup_type_id from xxfnd_lookup_types where lookup_type_name = '
                         || ''''
                         || c1_rec.src_lookup_type
                         || ''''
                         || ')';

                dbms_output.put_line('inside if ');
            END IF;

            CLOSE c1;
        END IF;

        dbms_output.put_line('SQL : ' || nvl(l_sql,'Not Defined') );
        IF
            l_sql IS NOT NULL
        THEN
            EXECUTE IMMEDIATE l_sql
            INTO l_output;
        END IF;
        dbms_output.put_line('Output : ' || l_output);
        RETURN l_output;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_segment_value;
------
    FUNCTION get_user_by_emp (
        p_emp_id IN NUMBER
    ) RETURN NUMBER IS

        l_user_id   NUMBER;
        CURSOR c2 IS SELECT
            user_id
                     FROM
            xxfnd_user
                     WHERE
            emp_id = p_emp_id
            AND nvl(active_yn,'N') = 'Y';

    BEGIN
        OPEN c2;
        FETCH c2 INTO l_user_id;
        IF
            c2%notfound
        THEN
            CLOSE c2;
            RETURN NULL;
        END IF;
        CLOSE c2;
        RETURN l_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_user_by_emp;
------
    FUNCTION get_user_by_role (
        p_role_id IN NUMBER
    ) RETURN NUMBER IS
        l_role_type    VARCHAR2(30);
        l_role_value   VARCHAR2(4000);
        l_user_id      NUMBER;
        CURSOR c1 IS SELECT
            role_type,
            role_value
                     FROM
            xxfnd_appr_roles
                     WHERE
            role_id = p_role_id
            AND nvl(active_yn,'N') = 'Y';
    BEGIN
        OPEN c1;
        FETCH c1 INTO
            l_role_type,
            l_role_value;
        IF
            c1%notfound
        THEN
            CLOSE c1;
            RETURN NULL;
        END IF;
        CLOSE c1;
        IF
            l_role_type = 'E'
        THEN
            l_user_id := get_user_by_emp(l_role_value);
        ELSIF l_role_type = 'Q' THEN
            RETURN NULL;
        -- needs to be changed 
        END IF;

        RETURN l_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_user_by_role;
------
    FUNCTION get_user_by_position (
        p_position_id IN NUMBER
    ) RETURN NUMBER IS
        l_user_id     NUMBER;
        l_person_id   NUMBER;
        CURSOR c1 IS SELECT
            person_id
                     FROM
            xxstg_positions
                     WHERE
            position_id = p_position_id
            AND nvl(active_yn,'N') = 'Y';
    BEGIN
        OPEN c1;
        FETCH c1 INTO l_person_id;
        IF
            c1%notfound
        THEN
            CLOSE c1;
            RETURN NULL;
        END IF;
        CLOSE c1;
        l_user_id := get_user_by_emp(l_person_id);
        RETURN l_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_user_by_position;
------
    FUNCTION get_appr_by_name (
        p_appr_type   IN VARCHAR2,
        p_appr_by     IN NUMBER
    ) RETURN VARCHAR2 IS
        l_desc   VARCHAR2(500);
        CURSOR c1 IS SELECT
            user_name_disp
                     FROM
            xxfnd_user
                     WHERE
            user_id = p_appr_by;
        CURSOR c2 IS SELECT
            role_name
                     FROM
            xxfnd_appr_roles
                     WHERE
            role_id = p_appr_by;

        CURSOR c3 IS SELECT
            position_name
                     FROM
            xxstg_positions
                     WHERE
            position_id = p_appr_by;
    BEGIN
        l_desc := NULL;
        IF
            p_appr_type = 'U'
        THEN
            OPEN c1;
            FETCH c1 INTO l_desc;
            CLOSE c1;
        ELSIF p_appr_type = 'R' THEN
            OPEN c2;
            FETCH c2 INTO l_desc;
            CLOSE c2;
        ELSIF p_appr_type = 'P' THEN
            OPEN c3;
            FETCH c3 INTO l_desc;
            CLOSE c3;
        END IF;
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_appr_by_name;
------
Function get_user_group(p_func_id      in      number,
                        p_attribute1   in      varchar2,
                        p_attribute2   in      varchar2,
                        p_attribute3   in      varchar2,
                        p_attribute4   in      varchar2,
                        p_attribute5   in      varchar2,
                        p_amount       in      number)
return number is

l_user_grp_id    number ;
---Krishna 
---This cursor will provide the user group id which is associated with 
---Func id and attr group id. From amount and to amount will be taken and used to filter out the user group
cursor c1 is 
    select  ac.user_grp_id
    from    xxfnd_func_approvals   fa, 
            xxfnd_appr_attr_group  ag,
            xxfnd_appr_attr_comb   ac
    where  fa.func_id             = p_func_id
    and    nvl(fa.active_yn, 'N') = 'Y'
    and    ag.attr_grp_id         = fa.attr_grp_id
    and    nvl(ag.active_yn, 'N') = 'Y'
    and    ac.attr_grp_id         = ag.attr_grp_id
    and    nvl(ac.active_yn, 'N') = 'Y'
    and    nvl(ac.attribute1, ' ' )  = nvl(p_attribute1, ' ' )
    and    nvl(ac.attribute2, ' ' )  = nvl(p_attribute2, ' ' )
    and    nvl(ac.attribute3, ' ' )  = nvl(p_attribute3, ' ' )
    and    nvl(ac.attribute4, ' ' )  = nvl(p_attribute4, ' ' )
    and    nvl(ac.attribute5, ' ' )  = nvl(p_attribute5, ' ' )
    and    p_amount between nvl(ac.amount_from, '') and nvl(ac.amount_to, '');
begin
    open  c1 ;
    fetch c1 into l_user_grp_id ;
    if c1%notfound then
       close c1 ;
       return null ;
    end if ;
    close c1 ;
    return l_user_grp_id ;
exception
    when others  then
         return null ;
end get_user_group ;
------   
procedure insert_appr_hist(p_func_id        in          number,
                           p_ref_id         in          number, -- PK of respective function 
                           p_level_no       in          number,
                           p_appr_id        in          number,
                           p_appr_role      in          varchar2,
                           p_flow_level     in          number,
                           p_usr_grp_id     in          number, 
                           p_cycle_no       in          number,
                           p_err_code       out         varchar2,
                           p_err_msg        out         varchar2 )  is
begin
  p_err_code     := '0';
  p_err_msg      := 'Success';

---Krishna
/* Insert the appproval list from all the levels which is associated with the particular and maintain in the xxfnd_func_approval_hist
table with status as Pending-P */

dbms_output.put_line('@insert_appr_hist: ') ;
     insert into xxfnd_func_approval_hist (
            appr_hist_id,  func_id,        func_ref_id,          seq_number,
            appr_role,     approver_id,    submission_date,      action_date,
            description,   status,         attribute_category,   attribute1,    
            attribute2,     attribute3,    attribute4,           attribute5,    
            attribute6,     attribute7,    attribute8,           attribute9,    
            attribute10,    created_by,    creation_date,        last_updated_by,      
            last_update_date,  last_update_login,flow_level,     user_grp_id,
            cycle_no,cycle_flag)
     values (
            xxfnd_appr_hist_id_s.nextval, p_func_id,   p_ref_id,  p_level_no,
            p_appr_role,                  p_appr_id,   null,   null,
            null,                         'P',         null,
            null,                         null,        null,      null,
            null,                         null,        null,      null,
            null,                         null,        
            -1,                           sysdate,     -1,        sysdate,        -1
            ,p_flow_level,p_usr_grp_id,  p_cycle_no,   'O' ) ;
            
dbms_output.put_line('@insert_appr_hist: p_func_id | p_ref_id |  p_level_no | p_appr_role | p_appr_id :' ||  
                       p_func_id ||' | '|| p_ref_id ||' | '||  p_level_no ||' | '|| p_appr_role ||' | '|| p_appr_id ) ;    
exception
  when others  then
     p_err_code := sqlcode;
     p_err_msg  := substr (sqlerrm, 1, 2000);
     dbms_output.put_line('@insert_appr_hist: exception  ' || p_err_msg) ;
     return;
end insert_appr_hist ;
------              
procedure update_appr_hist(p_func_id       in          number,
                          p_ref_id         in          number, -- PK of respective function 
                          p_level_no       in          number,
                          p_appr_id        in          number,
                          p_response       in          varchar2,
                          p_status         in          varchar2,
                          p_cycle_no       in          number,
                          p_err_code       out         varchar2,
                          p_err_msg        out         varchar2 )  is
begin
  p_err_code     := '0';
  p_err_msg      := 'Success';
   if p_appr_id is null then
          /* Update all the entries and IF CONDITION WILL WORK for when approved_by all column is 
             mentioned as 'N' in Appr_user table*/
           update xxfnd_func_approval_hist
           set    action_date         = sysdate,
                  description         = p_response,
                  status              = p_status,
                  last_updated_by     = -1,
                  last_update_date    = sysdate,
                  cycle_flag          = 'C'      
           where  func_id             = p_func_id
           and    func_ref_id         = p_ref_id
           and    flow_level          = p_level_no 
           and    cycle_no           =  p_cycle_no
           and    action_date is null;
           ----Status is R-rejected close the cycle.
            /* Update all the entries and if condition will work when user reject the transaction and 
                Rejection status will be updated based on the approver levels */
           if p_status= 'R' then
               update xxfnd_func_approval_hist
               set    last_updated_by     = -1,
                      last_update_date    = sysdate,
                      cycle_flag          = 'C'      
               where  func_id             = p_func_id
               and    func_ref_id         = p_ref_id
               and    cycle_no           =  p_cycle_no
               and    cycle_flag          = 'O';      
           end if;
   else
          /* Update all the entries and if condition will work for when approved_by all column is 
             mentioned as 'Y' in Appr_user table*/
           update xxfnd_func_approval_hist
           set    action_date         = sysdate,
                  description         = p_response,
                  status              = p_status,
                  last_updated_by     = -1,
                  last_update_date    = sysdate,
                  cycle_flag          = 'C' 
           where  func_id             = p_func_id
           and    func_ref_id         = p_ref_id
           and    flow_level          = p_level_no
           and    cycle_no           =  p_cycle_no
           and    approver_id         = p_appr_id 
           and    action_date is null;  
   end if ;
dbms_output.put_line('@update_appr_hist: p_func_id | p_ref_id |  p_level_no | p_appr_id | p_response | p_status :' ||  
                       p_func_id ||' | '|| p_ref_id ||' | '||  p_level_no ||' | '|| p_appr_id ||' | '|| p_response ||' | '|| p_status ) ;    
exception
  when others  then
     p_err_code := sqlcode;
     p_err_msg  := substr (sqlerrm, 1, 2000);
     return;
end update_appr_hist ;

----------
procedure submit_next_level(p_func_id        in          number,
                          p_ref_id         in          number, -- PK of respective function 
                          p_level_no       in          number,
                          p_cycle_no       in          number, 
                          p_err_code       out         varchar2,
                          p_err_msg        out         varchar2 )  is
begin
  p_err_code     := '0';
  p_err_msg      := 'Success';
/* Get the next approver id from the appproval_hist table and update the submission date alone for the current 
user who is supposed to approve */
                   update xxfnd_func_approval_hist
                   set    
                   submission_date=sysdate
                   where  func_id             = p_func_id
                   and    func_ref_id         = p_ref_id
                   and    flow_level          = p_level_no
                   and    cycle_no            = p_cycle_no
                   and    cycle_flag          = 'O';  
exception
  when others  then
     p_err_code := sqlcode;
     p_err_msg  := substr (sqlerrm, 1, 2000);
     return;
end submit_next_level;
--------
procedure submit_for_approval(p_func_id        in          number,
                              p_ref_id         in          number, -- PK of respective function 
                              p_user_grp_id    in          number,
                              p_level_no       in out      number,
                              p_amount         in          number,
                              p_flow_status    out         varchar2,
                              p_appr_id        out         number,
                              p_err_code       out         varchar2,
                              p_err_msg        out         varchar2 )  is
-- submit for approval
l_level_no            number;
l_level_name          varchar2(60) ;
l_flow_status         varchar2(60) ;
l_appr_id             number;
l_appr_role           varchar2(30) ;
l_appr_type           varchar2(30) ;
l_appr_by             number;
l_cycle_count         number;
l_seq_no              number;
l_seq_no_hist         number;
l_apr_tab             apr_tab ;

-----Krishna
----Change in cursor parameter to pull the appproval user id from the user group who is eligible for the  particular transactions.

cursor c1 is
  select  l.level_no level_no, l.level_name level_name, a.appr_role appr_role, a.appr_type appr_type, a.user_id user_id_1
  from    xxfnd_appr_user_group g, xxfnd_appr_user_levels l, xxfnd_appr_users a
  where   g.user_grp_id         = p_user_grp_id
  and     nvl(g.active_yn, 'N') = 'Y' 
  and     l.user_grp_id         = g.user_grp_id
  and     nvl(l.active_yn, 'N') = 'Y' 
  and     a.user_level_id       = l.user_level_id
  and     nvl(a.active_yn, 'N') = 'Y' 
  order by l.level_no ;

type t_level is table of c1%rowtype;
        l_user_find t_level;

/* This cursor to update the submission date for the current user who is suppose to approve. */
cursor c3 is
  select  flow_level,approver_id,seq_number
   from    xxfnd_func_approval_hist
    where  func_id             = p_func_id
   and    func_ref_id         = p_ref_id
   and    flow_level          >= p_level_no
   and    nvl(status,'P')     = 'P'
   order by seq_number;

begin
  p_err_code     := '0';
  p_err_msg      := 'Success';
/*Krishna
  Increment the cycle no if there is any exist for the function id and transaction.*/
select nvl(max(cycle_no),0) into l_cycle_count  from xxfnd_func_approval_hist where func_id=p_func_id and func_ref_id=p_ref_id;
l_cycle_count:=l_cycle_count+1;
l_seq_no := 0;
dbms_output.put_line('@submit_for_approval0: p_func_id | p_ref_id |  p_level_no | p_appr_id | p_flow_status :' ||  
                       p_func_id ||' | '|| p_ref_id ||' | '||  p_level_no ||' | '|| p_appr_id ||' | '|| p_flow_status ) ;
    open c1;
             fetch c1 bulk collect into l_user_find;
     close c1 ;
      if l_user_find.count > 0 then
                    for l_input in l_user_find.first .. l_user_find.last
                        loop
                          l_level_no     :=  l_user_find(l_input).level_no;
                          l_level_name   := l_user_find(l_input).level_name ;
                          l_appr_role    := l_user_find(l_input).appr_role;
                          l_appr_type    := l_user_find(l_input).appr_type ;
                          l_appr_id      := l_user_find(l_input).user_id_1;
                          l_seq_no := l_seq_no+1;
                          /* Insert the approvers list into history table */
                          insert_appr_hist(p_func_id, p_ref_id, l_seq_no, l_appr_id, l_appr_role,l_level_no,p_user_grp_id,l_cycle_count,p_err_code, p_err_msg);
                    end loop;
           open  c3 ;
           fetch c3 into p_level_no,p_appr_id,l_seq_no_hist ;
           close c3 ;
           /* Update the  submission date for the current approver*/
           submit_next_level (p_func_id, p_ref_id, p_level_no,l_cycle_count, p_err_code, p_err_msg );
      else
          /* If there is no user tagged with the user group id then the transaction will automatically get approve.*/
           dbms_output.put_line('@submit_for_approval1b : l_level_no is null ' || l_level_no) ;
             p_level_no       := null ;
             p_flow_status    := 'A' ;
             p_appr_id        := null ;    
      end if;
            dbms_output.put_line('@submit_for_approval2: p_func_id | p_ref_id |  p_level_no | p_appr_id | l_appr_role | p_flow_status :' ||  
                       p_func_id ||' | '|| p_ref_id ||' | '||  p_level_no ||' | '|| p_appr_id ||' | '|| l_appr_role ||' | '|| p_flow_status ) ;    

exception
  when others  then
     p_err_code := sqlcode;
     p_err_msg  := substr (sqlerrm, 1, 2000);
     return;
end submit_for_approval ;
------              
procedure update_response(p_func_id        in          number,
                          p_ref_id         in          number, -- PK of respective function 
                          p_user_grp_id    in          number,
                          p_level_no       in out      number,
                          p_appr_id        in out      number,
                          p_response       in          varchar2,
                          p_status         in          varchar2,
                          p_fwd_to         in          number,
                          p_flow_status    out         varchar2,
                          p_amount         in          number,
                          p_err_code       out         varchar2,
                          p_err_msg        out         varchar2 )  is
-- get response 
-- if approved, repeat steps till gets approved...
-- if rejected, stop the process
--              send back status
-- if change user, insert records in history
--              send back level, appr id, flow sts

l_level_no            number;
l_flow_status         varchar2(60) := null ;
l_appr_id             number;
l_appr_role           varchar2(30) ;
l_pending_yn          varchar2(1) ;
l_appr_by_all         varchar2(1) ;
l_cycle_count          number;  
l_seq_hist             number;

--To check all approved is required or not for the existing user level.
cursor c1 is
   select  l.appr_by_all
   from    xxfnd_appr_user_levels l 
   where   l.user_grp_id         = p_user_grp_id
   -- and     nvl(l.active_yn, 'N') = 'Y' 
   and     l.level_no            = nvl(p_level_no, 0) ;
cursor c2 is
   select  'Y'
   from    xxfnd_func_approval_hist
   where  func_id             = p_func_id
   and    func_ref_id         = p_ref_id
   and    flow_level          = p_level_no
   and    nvl(status,'P')     = 'P' ;

/* Get the cycle_no and seq number which is in open status  */
cursor c4 is
select seq_number,cycle_no from xxfnd_func_approval_hist
 where  func_id             = p_func_id
   and    func_ref_id         = p_ref_id
   and    flow_level          = p_level_no
   and     cycle_flag       = 'O'
   and     approver_id      = p_appr_id;

/* To update the submission date for the current user who is suppose to approve. */
cursor c3 is
  select  flow_level,approver_id
   from    xxfnd_func_approval_hist
    where  func_id             = p_func_id
   and    func_ref_id         = p_ref_id
   and    flow_level          >= p_level_no
   and    nvl(status,'P')     = 'P'
   and    cycle_no     = l_cycle_count
   order by seq_number;

begin
  p_err_code     := '0';
  p_err_msg      := 'Success';

   open  c1 ;
   fetch c1 into l_appr_by_all ;
   close c1 ;

   open  c4 ;
   fetch c4 into l_seq_hist,l_cycle_count;
   close c4;
   --the transaction is rejected by the user
   if p_status = 'R' then  -- Rejected 
        dbms_output.put_line('@update_response2: p_status - Rejected') ;
        -- Update all as Rejected in user level wise and close the current cycle...
        update_appr_hist(p_func_id, p_ref_id, p_level_no, null, p_response, p_status,l_cycle_count, p_err_code, p_err_msg ) ;
        p_flow_status := p_status ;
   --the transaction is forwarded by the user
   elsif p_status = 'F' then  -- Forwarded To 
        dbms_output.put_line('@update_response3: p_status - Forward') ;
        --Update the current user with flag close and mark the status F
        update_appr_hist(p_func_id, p_ref_id, p_level_no, p_appr_id, p_response, p_status,l_cycle_count ,p_err_code, p_err_msg ) ;
        --Insert the new user who is suppose the approve.
        insert_appr_hist(p_func_id, p_ref_id,l_seq_hist, p_fwd_to, l_appr_role,p_level_no,p_user_grp_id,l_cycle_count,p_err_code, p_err_msg);
        --Update the submission date for the current user.
        submit_next_level (p_func_id, p_ref_id, p_level_no,l_cycle_count, p_err_code, p_err_msg );
        p_flow_status := p_status ;
    --the transaction is approved by the user  
    else   
        dbms_output.put_line('@update_response4: p_status - Approved') ;
        dbms_output.put_line('@update_response5: l_appr_by_all ' || l_appr_by_all ) ;

           if nvl(l_appr_by_all, 'N') = 'N' then
             -- all approvals not required
              update_appr_hist(p_func_id, p_ref_id, p_level_no, null, p_response, p_status,l_cycle_count ,p_err_code, p_err_msg ) ;
           else
              dbms_output.put_line('@update_response5a: l_appr_by_all ' || l_appr_by_all ) ;
              -- all approvals required
              update_appr_hist(p_func_id, p_ref_id, p_level_no, p_appr_id, p_response, p_status,l_cycle_count ,p_err_code, p_err_msg ) ;
              dbms_output.put_line('@update_response6: l_pending_yn ' || p_level_no ) ;
           end if ;
               open  c3 ;
               fetch c3 into l_level_no,p_appr_id;
                 --All the users approved then we will mark the transaction with approved status.
                  if c3%NOTFOUND then
                      p_flow_status := 'A' ;
                      p_appr_id :=   null;
                      p_level_no := null;
                      close c3 ;
                  else
                  --Update the submission date for the next approver.
                      close c3 ;
                          if (l_level_no <> p_level_no) 
                          then
                            submit_next_level (p_func_id, p_ref_id, l_level_no,l_cycle_count, p_err_code, p_err_msg );
                            p_level_no := l_level_no;
                          end if;
                   end if;    
    end if ;
dbms_output.put_line('@update_response7: l_flow_status ' || l_flow_status ) ;
exception
  when others  then
     p_err_code := sqlcode;
     p_err_msg  := substr (sqlerrm, 1, 2000);
     return;
end update_response ;
------ Screen level Submit              
procedure submit_for_approval(p_func_id                  in          number,
                              p_ref_id                   in          number, -- pk of respective function 
                              p_level_no                 in out      number,
                              p_table_name               in          varchar2,
                              p_status_column            in          varchar2,
                              p_pk_column                in          varchar2,
                              p_amount                   in          number,
                              p_attribute1               in          varchar2,
                              p_attribute2               in          varchar2,
                              p_attribute3               in          varchar2,
                              p_attribute4               in          varchar2,
                              p_attribute5               in          varchar2,
                              p_flow_status              out         varchar2,
                              p_flow_with                out         number,
                              p_approver_name            out         varchar2,
                              p_approver_email           out         varchar2,
                              p_user_grp_id              out         varchar2,
                              p_err_code                 out         varchar2,
                              p_err_msg                  out         varchar2)  is


l_flow_status  varchar2(100)  := null;
l_appr_id      number;
l_err_code     varchar2(100);
l_err_msg      varchar2(100);
l_status       varchar2(100);
l_flow_with    number         := null;
l_flow_level   number         := null;
l_stmt         varchar2(5000);
l_user_grp_id  number ;
l_user_name    varchar2(100);
l_user_emailid varchar2(100);

cursor c_approve_details 
is
select user_name,user_email_id 
from xxfnd_user
where user_id = l_appr_id;


begin
    p_err_code     := '0';
    p_err_msg      := 'Success';
    -- Ger User Group  
    l_user_grp_id := get_user_group(p_func_id, p_attribute1, p_attribute2, p_attribute3, p_attribute4, p_attribute5,p_amount) ;
    if l_user_grp_id is null then
       p_err_code     := '-1';
       p_err_msg      := 'No Active Approval Attribute Group or User Group defined...';
       return ;
    end if ;
    l_stmt := 'update '|| p_table_name ||' set '|| p_status_column ||
              ' = :1,flow_status = :2,flow_with = :3,flow_level = :4, user_grp_id = :5 where '|| p_pk_column ||' = '||p_ref_id ; 
    submit_for_approval(p_func_id, p_ref_id, l_user_grp_id, p_level_no, p_amount, l_flow_status, l_appr_id, l_err_code, l_err_msg ) ;
    dbms_output.put_line('flow status ,app id,===>' ||  
                       l_flow_status ||' | '|| l_appr_id ||' | '||  l_err_code ||' | '|| l_err_msg ) ; 

    if l_flow_status = 'A' then
       l_status      := 'APR';
 	   l_flow_status := null ;
       l_flow_with   := null;
       l_flow_level  := null;
       l_user_grp_id := null;
    else
       l_status     := 'PEN';
       l_flow_with  := l_appr_id;
       l_flow_level := p_level_no;
    end if;
    execute immediate l_stmt using l_status,l_flow_status,l_flow_with,l_flow_level, l_user_grp_id ;
   dbms_output.put_line( l_status || '----' || l_flow_status || '------'  ||l_flow_with || '------'  || l_flow_level || '------'  ||l_user_grp_id );
   commit;
   dbms_output.put_line('STAUS==>  ' || p_err_code ||' ' || p_err_msg ) ;  
   
   open c_approve_details;
   fetch c_approve_details into l_user_name,l_user_emailid;
   close c_approve_details ;
   
   p_flow_status := l_status;
   p_level_no := p_level_no;
   p_flow_with := l_appr_id;
   p_approver_name := l_user_name;
   p_approver_email := l_user_emailid;
   p_user_grp_id := l_user_grp_id;
   

-- REST conversion
  APEX_JSON.open_object;
  APEX_JSON.write('submitResponse', l_user_emailid);
  APEX_JSON.close_object;  
   
exception
         when others  then
           p_err_code     := '1';
           p_err_msg      := substr (sqlerrm, 1, 2000);       
         dbms_output.put_line('STAUS==>  ' || p_err_code ||' ' || p_err_msg ) ;  

         
end submit_for_approval ;
------ Screen level Update              
procedure update_response(p_func_id        in          number,
                          p_ref_id         in          number, -- pk of respective function 
                          p_user_grp_id    in out      number,
                          p_level_no       in out      number,
                          p_appr_id        in out      number,
                          p_response       in          varchar2,
                          p_ar_status      in          varchar2,
                          p_fwd_to         in          number,
                          p_table_name     in          varchar2,
                          p_status_column  in          varchar2,
                          p_pk_column      in          varchar2,
                          p_amount         in          number, 
                          p_flow_status    out         varchar2,
                          p_approver_name  out         varchar2,
                          p_approver_email out         varchar2,
                          p_err_code       out         varchar2,
                          p_err_msg        out         varchar2) is

l_flow_status  varchar2(100) :=null;
l_appr_id      number        :=p_appr_id;
l_err_code     varchar2(100);
l_err_msg      varchar2(100); 
l_status       varchar2(100);
l_flow_with    number        := null;
l_flow_level   number        := null;
l_stmt         varchar2(5000);
l_flow_to      number        := p_fwd_to;
l_user_grp_id  number ;
l_user_name    varchar2(100);
l_user_emailid varchar2(100);


cursor c_approve_details 
is
select user_name,user_email_id 
from xxfnd_user
where user_id = l_flow_with;


begin
      p_err_code     := '0';
      p_err_msg      := 'Success';
      l_stmt  := 'update'||' '|| p_table_name ||' '||'set '|| p_status_column ||
	             ' = :1,flow_status = :2,flow_with = :3,flow_level = :4, user_grp_id = :5 where '|| p_pk_column ||'='||p_ref_id ; 
      update_response(p_func_id, p_ref_id, p_user_grp_id, p_level_no, l_appr_id, p_response, p_ar_status, p_fwd_to, l_flow_status, p_amount, l_err_code, l_err_msg ) ;

    if l_flow_status = 'A' then
       l_status := 'APR';
       l_flow_status := null ;
       l_flow_with   := null ;
       l_flow_level  := null ; 
       l_user_grp_id := null ;      
    elsif l_flow_status = 'R' then
       l_status := 'REJ';
       l_flow_status := null ;
       l_flow_with   := null ;
       l_flow_level  := null ;
       l_user_grp_id := null ;
    elsif l_flow_status = 'F' then 
       l_stmt := 'update'||' '|| p_table_name ||' '||'set flow_with = :1 where '|| p_pk_column ||'='||p_ref_id ; 
    else
       l_status      := 'PEN';
       l_flow_with   := l_appr_id;
       l_flow_level  := p_level_no;
       l_user_grp_id := p_user_grp_id ;
    end if ;

    if l_flow_status = 'F' then 
       execute immediate l_stmt using l_flow_to;
       l_flow_with:=l_flow_to;
    else
       execute immediate l_stmt using l_status,l_flow_status,l_flow_with,l_flow_level, l_user_grp_id ;
    end if;
    commit;     
    
   open c_approve_details;
   fetch c_approve_details into l_user_name,l_user_emailid;
   close c_approve_details ;
   
   p_flow_status := l_status;
   p_level_no := p_level_no;
   p_appr_id := l_flow_with;
   p_approver_name := l_user_name;
   p_approver_email := l_user_emailid;
   p_user_grp_id := p_user_grp_id;
   
exception
        when others  then
           p_err_code     := '1';
           p_err_msg      := substr (sqlerrm, 1, 2000);
      dbms_output.put_line('STAUS==>  ' || p_err_code ||' ' || p_err_msg ) ; 
      
-- REST converstion
  APEX_JSON.open_object;
  APEX_JSON.write('updateResponse', p_flow_status);
  APEX_JSON.close_object;
      
end update_response;
---------

end xxfnd_util_pkg;