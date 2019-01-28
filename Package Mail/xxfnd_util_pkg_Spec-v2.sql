create or replace package xxfnd_util_pkg is

type apr_rec is record (level_no            number,
                        flow_status         varchar2(60),
                        appr_id             number,
                        appr_role           varchar2(30) ) ;

type apr_tab is table of apr_rec
     index by binary_integer ; 

function get_segment_value( p_segment_column  in varchar2,
                            p_segment_value   in varchar2) 
         return varchar2 ;

function get_user_by_emp (p_emp_id   in    number)
         return number ;

function get_user_by_role (p_role_id   in    number)
         return number ;

function get_user_by_position (p_position_id   in    number)
         return number ;

function get_appr_by_name(p_appr_type   in      varchar2,
                          p_appr_by     in      number)
         return varchar2;

procedure insert_appr_hist(p_func_id        in          number,
                           p_ref_id         in          number, -- PK of respective function 
                           p_level_no       in          number,
                           p_appr_id        in          number,
                           p_appr_role      in          varchar2,
                           p_flow_level     in          number,
                           p_usr_grp_id     in          number, 
                           p_cycle_no       in          number,
                           p_err_code       out         varchar2,
                           p_err_msg        out         varchar2 ) ;

procedure update_appr_hist(p_func_id        in          number,
                          p_ref_id         in          number, -- PK of respective function 
                          p_level_no       in          number,
                          p_appr_id        in          number,
                          p_response       in          varchar2,
                          p_status         in          varchar2,
                          p_cycle_no       in          number,
                          p_err_code       out         varchar2,
                          p_err_msg        out         varchar2 ) ;



procedure submit_next_level (p_func_id        in          number,
                          p_ref_id         in          number, -- PK of respective function 
                          p_level_no       in          number,
                          p_cycle_no       in          number,
                          p_err_code       out         varchar2,
                          p_err_msg        out         varchar2 ) ;                          



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
                              p_err_msg                  out         varchar2) ; 

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
                          p_err_msg        out         varchar2) ;


end xxfnd_util_pkg;