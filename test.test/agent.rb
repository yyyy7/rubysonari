# frozen_string_literal: true
# == Schema Information
#
# Table name: agents
#
#  id                             :integer          not null, primary key
#  name_cn                        :string                                 # 中文全称
#  abbreviant                     :string                                 # 简称
#  name_en                        :string                                 # 英文名称
#  is_real                        :string                                 # 是否有效
#  remark                         :string                                 # 备注
#  deleted_at                     :datetime                               # 删除时间
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  counsellor_id                  :integer                                # 咨询顾问
#  agent_type                     :string                                 # 账户类型
#  phone                          :string                                 # 公司电话
#  fax                            :string                                 # 传真
#  management_id                  :integer                                # 市场经理
#  full_name_cn                   :string                                 # 中文全名
#  developer_id                   :integer                                # 开发人id
#  no                             :string                                 # 编号
#  agent_manage_type              :string                                 # 代理经营类型
#  special_count_remark           :boolean          default("false")      # 特殊统计标记
#  initial_account_status         :string           default("close")      # 初始账号状态
#  name_cn_pinyin                 :string                                 # 名称全称拼音
#  abbreviant_pinyin              :string                                 # 名称简称拼音
#  temp_full_name_cn              :string                                 # 代理全称
#  foreign_name                   :string                                 # 对外名称(对学生)
#  visa_service_fee_is_invoiced   :boolean          default("false")      # 签证服务费是否开票(默认false)
#  visa_service_fee_is_deductible :boolean          default("false")      # 签证服务费是否抵扣(默认false)
#  agent_category                 :string                                 # 代理类型：大代理(senior_agent)，中小代理(fresh_agent)
#  sales_manager_id               :integer                                # 关联销售经理ID
#  follow_up_counsellor_id        :integer                                # 后续经理
#  is_excel                       :boolean                                # 是否通表上传
#  communication_control          :boolean          default("false")      # 是否开通留言功能
#  receive_email                  :boolean          default("true")       # 代理机构是否接收待办邮件
#  is_work_process_task           :boolean          default("true")       # 是否走流程
#  is_open_financial_management   :boolean          default("false")      # 是否开启财务管理
#  is_send_file_email             :boolean          default("true")       # 是否发送OFFER/COE通知邮件附件
#  former_popedom_id              :integer                                # 原先辖区
#  new_popedom_id                 :integer                                # 新辖区
#  invalid_reason                 :string                                 # 无效原因
#  specify_email                  :string                                 # 代理指定邮箱
#  is_meijia                      :boolean          default("false")      # 是否为美加代理
#  visible_children_students      :boolean          default("false")      # 允许母公司管理员查看在子公司学生
#  material_counsellor_id         :integer                                # 材料顾问
#

class Agent < ApplicationRecord
  acts_as_taggable

  acts_as_taggable_on :skills, :interests

  # 代理基本信息这个页面后端统一返回给前端英文
  # enum special_count_remark: { "是" => true, "否" => false }

  # validates :no, uniqueness: true, scope: :id

  has_many :orders, dependent: :destroy

  has_many :students, dependent: :destroy

  has_many :plans, through: :students

  has_one :enterprise, as: :resource, dependent: :destroy

  has_many :employees, through: :enterprise

  has_many :users, through: :employees

  has_many :contracts, dependent: :destroy

  has_many :commission_infos, through: :contracts

  # FIXME: 后续这里需要删除 关联咨询顾问
  belongs_to :counsellor, class_name: "User", foreign_key: :counsellor_id
  belongs_to :user, class_name: "User", foreign_key: :counsellor_id

  has_many :student_visas, dependent: :destroy

  has_one :financial_contact, dependent: :destroy

  has_one :bank_account, as: :owner, dependent: :destroy

  has_one :address, as: :owner, dependent: :destroy

  has_one :attachment_group, as: :resource, dependent: :destroy

  # 关联付费注册
  has_many :enter_school_registers, dependent: :destroy

  # 关联组织发票信息
  has_many :org_invoice_infos, as: :owner, dependent: :destroy

  # 关联结算
  has_many :settles, as: :receiver, dependent: :destroy

  # 关联发票
  has_many :invoices, as: :receiver, dependent: :destroy

  # 多态关联老系统数据表
  has_one :former_system_record, as: :current_system, dependent: :destroy

  # 关联留学课程实例
  has_many :study_abroad_course_instances, dependent: :destroy

  # 关联佣金信息
  has_many :commission_infos, as: :owner, dependent: :destroy

  #关联咨询顾问
  belongs_to :counsellor, class_name: "User", foreign_key: :counsellor_id
  belongs_to :user, class_name: "User", foreign_key: :counsellor_id

  # 关联销售经理
  belongs_to :sales_manager, class_name: "User", foreign_key: :sales_manager_id

  belongs_to :manager, class_name: "User", foreign_key: :management_id

  belongs_to :developer, class_name: "User", foreign_key: :developer_id

  #* 材料顾问是一个岗位下的所有员工
  belongs_to :material_counsellor, class_name: "Position", foreign_key: :material_counsellor_id

  #大代理多对多关联咨询顾问
  has_many :agent_users, dependent: :destroy
  has_many :counsellors, through: :agent_users, source: "user", dependent: :destroy

  # 代理关联后续经理
  belongs_to :follow_up_counsellor, class_name: "User", foreign_key: :follow_up_counsellor_id

  # 多对多关联代理账单
  has_many :agent_billing_relations, dependent: :destroy
  has_many :agent_billings, through: :agent_billing_relations

  # 作为主要代理(提供收款账户和代理结算人信息)关联账单
  has_many :main_billings, as: :to, dependent: :destroy, class_name: AgentBilling.name

  # 关联代理的明细
  has_many :agent_settle_detail_infos, as: :owner, dependent: :destroy

  # 原先辖区 关联数据字典
  belongs_to :former_popedom, class_name: "DataDictionary", foreign_key: :former_popedom_id

  # 新辖区 关联数据字典
  belongs_to :new_popedom, class_name: "DataDictionary", foreign_key: :new_popedom_id

  #关联公告浏览记录
  has_many :content_browse_records, dependent: :destroy

  # 一对一关联代理画像
  has_one :agent_portrait, dependent: :destroy

  # 和代理奖励政策多对多关联
  has_many :agent_incentive_policies, dependent: :destroy
  has_many :incentive_policies, through: :agent_incentive_policies

  # 代理有效性
  has_many :agent_validities, dependent: :destroy

  # 代理拜访
  has_many :visit_reports, dependent: :destroy

  # 邮件转发规则配置
  has_many :mail_rules, dependent: :destroy

  scope :agent_search_fuzzy_name, -> (fuzzy_name) do
    where("upper(agents.name_cn) like :keyword or upper(agents.abbreviant) like :keyword or upper(agents.name_en)
          like :keyword or upper(agents.full_name_cn) like :keyword or upper(agents.name_cn_pinyin) like :keyword or
          upper(agents.abbreviant_pinyin) like :keyword", keyword: "%#{fuzzy_name&.upcase}%")
  end

  # 验证代理编号唯一
  # TODO validate在实际插入时会有问题
  validates :no, uniqueness: true, allow_nil: true

  validates_uniqueness_of :name_cn, message: "^中文全称：%{value} 已经存在"
  validates_uniqueness_of :abbreviant, message: "^简称：%{value} 已经存在"

  before_save :generate_pinyin_when_create, unless: :skip_callbacks
  after_create :send_email_when_create

  # 导入模型公共方法
  include BaseModelConcern

  # 代理经营类型
  module AgentManageType
    include Dictionary::Module::I18n

    # 直营
    DIRECT = "direct"

    # 普通
    NORMAL = "normal"
  end

  module InitialAccountStatus
    include Dictionary::Module::I18n

    # 已开通
    OPEN = "open"

    # 未开通
    CLOSE = "close"

    # 信息不全
    PROBLEM = "problem"
  end

  module AgentCategory
    include Dictionary::Module::I18n

    # 大代理
    SENIOR_AGENT = "senior_agent"

    #中小代理
    FRESH_AGENT = "fresh_agent"

    # 海外代理
    ON_SHORE = "on_shore"

    # 海外代理和大代理分类（同样的业务逻辑处理）
    SENIOR_SHORE = [SENIOR_AGENT, ON_SHORE]

    # 选项
    OPTIONS = get_all_options

    # 全部
    ALL = get_all_values
  end

  # 查询代理人列表
  def self.query_by_params(params)
    agents = []
    page_source = nil
    count_all = nil
    response = Response.rescue do |_res|
      user = params[:user]
      search_params = params[:search]
      page = params[:page]
      per = params[:per]
      is_page = false
      count_sql = nil
      page_source = params[:page_source]
      search_params = {} if search_params.blank?
      if user&.employee.present?
        # TODO: 20181129跟嘉兴哥讨论，所有涉及到数据的地方全部使用用户的角色控制，因为用户角色总是包含 岗位角色和用户新增自定义角色
        current_positions = user.roles.pluck(:name).uniq.compact

        # 管理员和其他角色不受限制 - 并且需要添加上 用户如果包好部门经理角色也不瘦限制
        # FIXME: PM - 24237 - 代理信息管理页面，需要给财务相关角色（财务专员，出纳）提供查看所有代理数据的权限。
        # 20181217日 - 签证顾问权限先不开启 （代理管理）
        if (current_positions & Role::Name::MANAGER_ROLE).present? ||
            (current_positions & Role::Name::FINANCE_RELATION).present? ||
            current_positions&.include?(Role::Name::DEPARTMENT_MANAGER)
          # FIXME: 不需要处理

        else
          # TODO: 根据嘉兴哥口头表述，目前除去管理角色外，其他情况只需要根据一下情况判断就可以了，不需要添加角色判断。
          # FIXME: 最后一个agent_users是兼容处理  兼容下面的语句
          search_params["agents.management_id&or&agents.sales_manager_id&or&agents.follow_up_counsellor_id&or&agent_users.user_id"] = user.id
        end
      end

      search_params.delete_if { |_k, v| v.blank? }

      # FIXME: 大代理会关联多个咨询顾问 - 这里需要分情况处理
      # search_params["counsellors.id&or&agent_counsellors.id"] = search_params.delete("agents.counsellor_id") if search_params["agents.counsellor_id"].present?
      search_params["agent_counsellors.id"] = search_params.delete("agent_counsellors.id") if search_params["agent_counsellors.id"].present?

      if page.present? && per.present?
        is_page = true
        offset = (page.to_i - 1) * per.to_i
        limit = per.to_i
      end

      # 删除默认排序条件
      search_params.delete("order") || search_params.delete(:order)

      if search_params.keys.length == 0
        search_string = "where agents.deleted_at is NULL"
      else
        search_string = ApplyForm.make_search_url(search_params) + " and agents.deleted_at is NULL"
      end

      log "删除这里的查询条件 search_params = #{search_params}-----------search_string = #{search_string}"

      if page_source == "apply_form_index"
        sql = "SELECT
                agents.id,
                agents.abbreviant,
                agents.name_cn,
                agents.management_id,
                COALESCE(to_char(agents.created_at, 'YYYY-MM-DD HH24:MI:SS'), '') AS created_at,
                COALESCE(to_char(agents.updated_at, 'YYYY-MM-DD HH24:MI:SS'), '') AS updated_at
              FROM agents
              #{search_string} ORDER BY created_at DESC"
      else
        sql = "SELECT * FROM (SELECT DISTINCT ON (agents.id)
              (
                SELECT array_to_json(array_agg(row_to_json(d)))
                FROM (
                       SELECT
                         counsellors.id,
                         counsellors.real_name,
                         counsellors.username,
                         counsellors.email,
                         counsellors.phone
                       FROM users counsellors
                         LEFT JOIN agent_users ON agent_users.user_id = counsellors.id AND agent_users.deleted_at IS NULL
                       WHERE agents.id = agent_users.agent_id
                       ORDER BY id ASC
                     ) d
              )                                                                 AS counsellors,
              (
                SELECT row_to_json(d)
                FROM (
                       SELECT
                         id,
                         real_name
                       FROM users counsellors
                       WHERE agents.counsellor_id = counsellors.id
                       ORDER BY id ASC
                     ) d
              )                                                                 AS counsellor,
              (
                SELECT row_to_json(d)
                FROM (
                       SELECT
                         id,
                         real_name
                       FROM users managers
                       WHERE agents.management_id = managers.id
                       ORDER BY id ASC
                     ) d
              )                                                                 AS manager,
              agents.id,
              agents.no,
              (CASE WHEN agents.is_work_process_task = 'true'
                THEN '是'
               ELSE '否' END)                                                   AS is_work_process_task,
              (CASE WHEN agents.is_send_file_email = 'true'
                              THEN '开启'
               ELSE '关闭' END)                                                   AS is_send_file_email,
              (CASE WHEN agents.is_open_financial_management = 'true'
                THEN '开启'
               ELSE '关闭' END)                                                 AS is_open_financial_management,
              (CASE WHEN agents.receive_email = 'true'
                THEN '开启'
               ELSE '关闭' END)                                                 AS receive_email,
              (CASE WHEN agents.communication_control = 'true'
                THEN '开启'
               ELSE '关闭' END)                                                 AS communication_control,
              agents.agent_category,
              agents.abbreviant,
              agents.name_cn,
              agents.name_en,
              agents.is_real,
              agents.remark,
              agents.is_excel,
              agents.initial_account_status,
              agents.material_counsellor_id,
              COALESCE(to_char(agents.created_at, 'YYYY-MM-DD HH24:MI:SS'), '') AS created_at,
              COALESCE(to_char(agents.updated_at, 'YYYY-MM-DD HH24:MI:SS'), '') AS updated_at,
              max(contracts.end_date) OVER (PARTITION BY contracts.agent_id) AS end_date,
              agents.agent_type,
              agents.agent_category,
              follow_up_counsellors.id                                          AS follow_up_counsellor_id,
              follow_up_counsellors.real_name                                   AS follow_up_counsellor,
              sales_managers.id                                                 AS sales_manager_id,
              sales_managers.real_name                                          AS sales_manager,
              (CASE WHEN agent_category = 'senior_agent' THEN '大代理'
                    WHEN agent_category = 'fresh_agent' THEN '中小代理'
                    WHEN agent_category = 'on_shore' THEN 'onshore代理'
                    ELSE ''
              END)                                                              AS agent_category_zh
            FROM agents
              LEFT JOIN users sales_managers
                ON sales_managers.id = agents.sales_manager_id AND
                   sales_managers.deleted_at IS NULL
              LEFT JOIN users follow_up_counsellors
                ON follow_up_counsellors.id = agents.follow_up_counsellor_id AND follow_up_counsellors.deleted_at IS NULL
              LEFT JOIN users counsellors ON counsellors.id = agents.counsellor_id AND counsellors.deleted_at IS NULL
              LEFT JOIN agent_users ON agent_users.agent_id = agents.id and agent_users.deleted_at is null
              LEFT JOIN users agent_counsellors ON agent_counsellors.id = agent_users.user_id and agent_counsellors.deleted_at is null
              LEFT JOIN contracts ON contracts.agent_id = agents.id AND contracts.deleted_at IS NULL
            #{search_string}
            ORDER BY agents.id) temp_tables ORDER BY created_at DESC"

        count_sql = "SELECT count(*) from (#{sql}) AS count_all;"
      end

      sql = is_page ? (sql + " LIMIT #{limit} OFFSET #{offset};") : (sql + ";")

      agents = ActiveRecord::Base.connection.select_all sql

      if count_sql.present?
        count_all = ActiveRecord::Base.connection.select_all count_sql
        count_all = count_all.rows[0][0].to_i
      end
    end
    [response, agents, page_source, count_all]
  end

  # 是否可以通过导入excel新建学生
  def self.is_excel_by_params(params)
    is_excel = false
    response = Response.rescue do |_res|
      user = params[:user]
      if (user.roles & [Role.find_by_name("agent_manager"), Role.find_by_name("agent"), Role.find_by_name("agent_admin"), Role.find_by_name("agent_counsellor")]).present?
        agent = user&.employee&.enterprise&.resource
        is_excel = true if agent&.is_excel
      else
        is_excel = true
      end
    end
    [response, is_excel]
  end

  # 待办邮件提醒批量开关
  def self.update_receive_email(params)
    response = Response.rescue do |res|
      user_ids = params[:user_ids]
      agent_ids = params[:agent_ids]
      status = params[:status]
      # 代理端批量开关用户的待办邮件提醒
      if user_ids.present?
        users = User.where(id: user_ids)
        users.update_all(receive_email: status)
        # 更新代理机构的receiver_email字段
        agent = users&.first&.employee&.enterprise&.resource
        receive_email_status = agent.users.pluck(:receive_email)
        if receive_email_status.include? true
          agent.update(receive_email: true)
        else
          agent.update(receive_email: false)
        end
        # 运营端批量开关待办邮件提醒
      elsif agent_ids.present?
        agents = Agent.where(id: agent_ids)
        agents.each do |agent|
          agent.users.update_all(receive_email: status) if agent.users.present?
          agent.update(receive_email: status)
        end
      end
    end
    response
  end

  # 导出功能批量开关
  def self.update_is_agent_export(params)
    user_ids = params[:user_ids]
    status = params[:status]
    response = Response.rescue do |res|
      User.transaction do
        users = User.where(id: user_ids)
        if users.present?
          users.each do |user|
            user.update!(is_agent_export: status)
          end
        end
      end
    end
    response
  end

  # 批量修改留言功能权限
  def self.update_communication_control_by_params(params)
    response = Response.rescue do |res|
      agent_ids = params[:agent_ids]
      status = params[:status]
      agents = Agent.where(id: agent_ids)
      agents.each do |agent|
        agent.update(communication_control: status)
      end
    end
    response
  end

  # 批量修改是否走流程
  def self.update_work_process_task_by_params(params)
    response = Response.rescue do |res|
      user = params[:user]
      user = User.find user.id
      role_names = user.role_names
      column_name = params[:column_name]
      # todo pm21496 暂时这么修改 等小雨回来再改 这里只有是否开启财务管理按钮 不需要去限定谁能修改
      # todo pm21487 第三个问题 修改offer和coe发送功能需开放
      res.raise_error(I18n.t("activerecord.errors.not_permission")) unless (role_names & Role::Name::MANAGER_ROLE).present? || %w{is_send_file_email is_open_financial_management}.include?(column_name)
      res.raise_error(I18n.t("activerecord.errors.missing_required")) unless validate_all_present?(column_name)

      agent_ids = params[:agent_ids]
      status = params[:status]
      Agent.where(id: agent_ids).each { |x| x.update!("#{column_name}" => status) }
    end
    response
  end

  def self.batch_destroy_agents_by_params(params)
    response = Response.rescue do |res|
      Agent.transaction do
        agent_ids = params.values_at(:agent_ids)

        agents = Agent.eager_load(:students, :enter_school_registers, :orders, :student_visas, :agent_billing_relations, :agent_settle_detail_infos).where(id: agent_ids)

        error_messages = []

        agents.each do |agent|
          error_messages.push("所选数据：#{agent.abbreviant} 不符合删除条件！") unless validate_all_blank?(agent.students, agent.enter_school_registers,
                                                                                              agent.orders, agent.student_visas, agent.agent_billing_relations,
                                                                                              agent.agent_settle_detail_infos)
        end

        # FIXME: 处理的比较特殊前端需要拿到所有不符合的代理数据
        res.raise_error(error_messages) if error_messages.presence

        # 删除
        agents.each(&:destroy!)
      end
    end

    return response
  end

  # 批量修改代理级别
  def self.update_change_agent_category_task_by_params(params)
    response = Response.rescue do |res|
      agent_ids = params[:agent_ids]
      agent_category = params[:agent_category]
      agents = Agent.where(id: agent_ids)

      res.raise_error("缺少必要参数") unless validate_all_present?(agent_ids, agent_category)
      res.raise_error("您选中的代理级别不一致") unless agents.pluck(:agent_category).uniq.length == 1

      Agent.where(id: agent_ids).each { |x| x.update!(agent_category: agent_category) }
    end

    return response
  end

  # 重新发送账号密码给代理
  def self.resend_password(params)
    response = Response.rescue do |res|
      user_id = params[:user_id]
      email = params[:email]
      market_manager_email = params[:market_manager_email]
      phone = params[:phone]

      user = User.find(user_id)
      res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if user.blank?

      number_attribution = params[:number_attribution] || user.number_attribution
      password = CodeFormat.agent_user_password
      user.password = password
      user.number_attribution = number_attribution
      user.save!

      vars = ({ "to" => ["#{email}"], "sub" => { "%name%" => ["#{phone} 或 #{email}"], "%password%" => [password] } })
      AtyunEmail::Providers::Sendcloud.send_email({ xsmtpapi: vars, :templateInvokeName => "invite_agent" }, :allwin, {}) if is_send_email?(email)
      cc_vars = ({ "to" => ["#{market_manager_email}"], "sub" => { "%name%" => ["#{phone} 或 #{email}"], "%password%" => [password] } })
      AtyunEmail::Providers::Sendcloud.send_email({ xsmtpapi: cc_vars, :templateInvokeName => "invite_agent" }, :allwin, {}) if is_send_email?(market_manager_email)
      # 发送手机短信
      params = { phone: phone, content: { phone: phone, email: email, password: password }, template_id: "6107", msg_type: 0 }
      AtyunSms.send_sms(:SendCloud, params, AtyunSmsSetting.sendcloud) if number_attribution == 'china' && is_send_sms?(phone)
    end
    response
  end

  def self.employee_users_by_params(params)
    agents = []
    is_need_users = nil
    response = Response.rescue do |_res|
      Student.transaction do
        search_params = params[:search] || {}
        is_open = params[:is_open]
        user = params[:user]
        # 设置返回数据
        page = params[:page] || 1
        per = params[:per] || 50
        search_params["agent_category"] = params[:agent_category] if params[:agent_category].present?
        is_need_users = params[:is_need_users]
        role_names = user.role_names

        if (role_names & [Role::Name::AGENT_ADMIN, Role::Name::AGENT_COUNSELLOR]).present?
          agent = user.get_agent
          if agent.visible_children_students && params[:need_visiblecs].present?
            agents = agent.agents_through_children_enterprise | [agent]
          else
            agents = [agent].compact
          end
        else
          if user&.employee.present? && params[:case].blank? # pm 17579
            if user.employee&.positions.present?
              # TODO: - 讨论结果 - 在原先的基础上 如果需要查看更多的数据，需要富裕一个部门经理的用户角色
              current_positions = user.positions.pluck(:code).compact

              # 管理员和其他角色不受限制 - 并且需要添加上 用户如果包好部门经理角色也不瘦限制
              if (current_positions & Role::Name::MANAGER_ROLE).present? || role_names.include?(Role::Name::DEPARTMENT_MANAGER)
              elsif current_positions.include?(Role::Name::MARKET_MANAGER)
                search_params["agents.management_id"] = user.id
              elsif (Role::Name::PLAN_CODES & current_positions).present? # 仅包含这几个角色的时候才需要做这个查询限制
                search_params["users.id"] = user.id
              end
            end
          end

          # 支持模糊搜索
          search_name = search_params.delete("like_agents.abbreviant")

          if is_open.present? && search_name.present?
            agents = Agent.agent_search_fuzzy_name(search_name).eager_load(:counsellor, :manager, :developer, :users)
                         .search_by_params(search_params).where(initial_account_status: is_open)
                         .order(updated_at: :desc).page(page).per(per).distinct
          elsif is_open.blank? && search_name.present?
            agents = Agent.agent_search_fuzzy_name(search_name).eager_load(:counsellor, :manager, :developer, :users)
                         .search_by_params(search_params).order(updated_at: :desc).page(page).per(per).distinct
          elsif is_open.present? && search_name.blank?
            agents = Agent.eager_load(:counsellor, :manager, :developer, :users).search_by_params(search_params)
                         .where(initial_account_status: is_open).order(updated_at: :desc).page(page).per(per).distinct
          else
            agents = Agent.eager_load(:counsellor, :manager, :developer, :users)
                         .search_by_params(search_params).order(updated_at: :desc).page(page).per(per).distinct
          end
        end
      end
    end

    [response, agents, is_need_users]
  end

  #批量修改用户 对应角色id 顾问，经理人
  def self.update_consultors(params)
    agents = []
    response = Response.rescue do |res|
      Agent.transaction do
        user = params[:user]
        # TODO: 判断用户身份
        # agent = user.employee.enterprise.resource
        if params[:counselors].present?
          counselors = params[:counselors]
          counselors.each do |agent_id, user_ids|
            agent = Agent.find_by_id agent_id
            res.raise_error("查询数据不存在") if agent.blank?
            # FIXME: replace不能触发agent的 updated_at更新
            on_touch_many_to_many(AgentUser, 'agent_id', agent, 'user_id', user_ids)
          end
        end

        #经理
        if params[:managers].present?
          managers = params[:managers]
          managers.each do |k, v|
            agent = Agent.find_by_id k
            res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?
            agent.update!(management_id: v)
          end
        end

        # pm17399 销售经理
        if params[:sales_managers].present?
          sales_managers = params[:sales_managers]
          sales_managers.each do |k, v|
            agent = Agent.find_by_id k
            res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?
            agent.update!(sales_manager_id: v)
          end
        end

        params[:material_counsellor].to_a.each do |k, v|
          agent = Agent.find_by_id k
          res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?
          agent.update!(material_counsellor_id: v)
        end
      end
    end
    [response, agents]
  end

  def self.create_with_params(params)
    agent = nil
    response = Response.rescue do |res|
      current_user = params[:user]
      Agent.transaction do
        agent_params = params.require(:agent).permit!

        res.raise_error(I18n.t("activerecord.errors.data_type_error")) unless Agent::AgentType::ALL.include? agent_params[:agent_type]

        address_params = params.require(:address).permit!

        files = params[:files]

        contract_files = params[:contract_files]

        counsellor_ids = agent_params.delete(:counsellor_ids)

        agent = Agent.new(agent_params)

        # 生成代理编号

        agent.no = generate_agent_no

        agent.save!

        counsellor_ids.each { |x| AgentUser.find_or_create_by!(user_id: x, agent_id: agent.id) } if counsellor_ids.length != 0

        # PM - 19351查找代理佣金会计的岗位，给当前岗位下面的所有员工发送站内信
        position = Position.find_by_code "agency_commission_accounting"
        agent_account_users = User.left_joins(employee: :positions).where(positions: { id: position.id }).distinct if position.present?
        if agent_account_users.present?
          content = "【代理管理】新建代理：【#{agent.abbreviant}】."
          agent_account_users.each do |account_user|
            AuditForm.v2_send_internal_message({ to_id: account_user.id, message_type: Message::MessageType::CREATE_AGENT_NOTICE, content: content,
                                                 extra: nil, resource_id: agent.id, resource_type: "Agent", jump_type: Message::JumpType::CREATE_AGENT_TO_DETAIL_INFO, jump_owner_id: current_user.id, jump_owner_type: "User" })
          end
        end

        address_params.merge!({ owner: agent })

        # pm 16598 合同
        contract_params = {}
        if params[:contract].present?
          contract_params = params.require(:contract).permit!
          res.raise_error("数据类型错误") unless Contract.include_type?(contract_params[:contract_type])
          contract_params.merge!({ agent_id: agent.id })

          must_contratc_params = contract_params.values_at(:initial_commission_rate, :start_date, :end_date)

          res.raise_error(I18n.t("activerecord.errors.missing_required")) if Agent.validate_blank?(must_contratc_params)

          contract = Contract.create!(contract_params)
        end

        # 澳币收款账户信息
        if params[:bank_account].present?
          bank_accounts_params = params.require(:bank_account).permit!
          bank_accounts_params.merge!({ owner: agent, bank_account_purpose: BankAccount::AccountUse::RECEIVER })
          bank_account = BankAccount.create!(bank_accounts_params)
        end

        # 财务结算人信息
        if params[:financial_contact].present?
          financial_contact_params = params.require(:financial_contact).permit!
          financial_contact_params.merge!({ agent_id: agent.id })
          financial_contact = FinancialContact.create!(financial_contact_params)
        end

        address = Address.create!(address_params)

        if contract_files.present?
          contract_attachment_group = AttachmentGroup.create!(resource: contract, operator: current_user, catalog_type: AttachmentGroup::CatalogType::Contract)
          Attachment.add_attachment(contract_files, contract_attachment_group, res)
        end

        limited = DataDictionary.where(value: 'AAedu International Limited').first
        subject = (random_contract = agent.contracts.first).present? ? random_contract.subject : limited
        res.raise_error(I18n.t('activerecord.errors.data_not_exist')) if subject.blank?
        #新建佣金信息
        if params[:commission_info].present?
          commission_info_params = params[:commission_info].permit(:settle_start_date, :settle_end_date, :contract_version, :forecast_rate, :closure_num, :year_rate, :is_special, :special_rate)
          res.raise_error(I18n.t("activerecord.errors.missing_required")) if commission_info_params.blank?
          commission_info_params.merge!(owner_id: agent.id, owner_type: agent.class, subject_id: subject.id)
          commission_info = CommissionInfo.new(commission_info_params)
          commission_info.year_rate ||= 0
          commission_info.save!
        else
          # 默认佣金信息
          commission_info_params = {
              contract_version: "201607",
              forecast_rate: "0.5",
              is_special: false,
              special_rate: "0",
              subject_id: subject.id
          }
          commission_info_params.merge!(owner_id: agent.id, owner_type: agent.class)
          commission_info = CommissionInfo.new(commission_info_params)
          commission_info.year_rate = 0
          time = Time.now
          if time.month < 7
            commission_info.settle_start_date = "#{time.year - 1}-07-01"
            commission_info.settle_end_date = "#{time.year}-06-30"
          else
            commission_info.settle_start_date = "#{time.year}-07-01"
            commission_info.settle_end_date = "#{time.year + 1}-06-30"
          end
          commission_info.closure_num = 0
          commission_info.save!
        end

        attachment_group = AttachmentGroup.create!(resource: agent, operator: current_user, catalog_type: AttachmentGroup::CatalogType::AGENT)
        #基础资料附件
        Attachment.add_attachment(files, attachment_group, res) if files.present?

        #创建公司
        enterprise_params = params[:enterprise] || {}
        if enterprise_params.present?
          if enterprise_params[:parent_company_id].present?
            parent_id = Agent.find(enterprise_params[:parent_company_id]).enterprise.id
            Enterprise.create(resource: agent, name: agent_params[:name_cn], parent_id: parent_id)
          elsif enterprise_params[:subsidiary_company_ids].present?
            enterprise = Enterprise.create(resource: agent, name: agent_params[:name_cn])
            subsidiary_companies = Array.new
            enterprise_params[:subsidiary_company_ids].each do |sub_id|
              sub_com = Agent.find(sub_id).enterprise
              #如果子公司之前为母公司，将其子公司设置为默认的母公司
              if sub_com.children.present?
                sub_com.children.each do |sub|
                  sub.update(parent_id: nil)
                end
              end
              subsidiary_companies << sub_com
            end
            enterprise.add_child subsidiary_companies
          else
            res.raise_error(I18n.t('activerecord.errors.data_type_error'))
          end
        else
          enterprise = Enterprise.create(resource: agent, name: agent_params[:name_cn])
        end

        # 新建代理画像
        AgentPortrait.create!(agent: agent)

        # 和奖励政策建立不包括的关系
        IncentivePolicy.all.each { |policy| AgentIncentivePolicy.create!(agent_id: agent.id, incentive_policy_id: policy.id) }

        # 新建代理有效性 pm23997
        valid_category = DataDictionaryCategory.where(class_name: 'Agent', attribute_name: 'validity').first
        valid = DataDictionary.where(name: '有效', owner: valid_category).first
        new_agent = DataDictionary.where(name: '新代理运营', owner: valid_category).first
        new_build = DataDictionary.where(name: '初建档', owner: valid_category).first
        res.raise_error("当前操作不能被正确执行") if valid_category.blank? || valid.blank? || new_agent.blank? || new_build.blank?
        valid_params = {
            operator_type: AgentValidity::OperatorType::MARKET_MANAGER,
            validity_id: valid.id,
            valid_agent_type_id: new_agent.id,
            valid_specific_type_id: new_build.id,
            build_file_year: AgentValidity.cal_year(agent.created_at),
            agent_id: agent.id
        }
        AgentValidity.find_or_create_by!(valid_params)
        AgentValidity.find_or_create_by!(valid_params.merge!(operator_type: AgentValidity::OperatorType::SALES_MANAGER))

      end
    end
    [response, agent]
  end

  # 生成代理编号
  def self.generate_agent_no
    agent_no = "A" + CodeFormat.get_rand_number(6)
    if Agent.find_by_no(agent_no).present?
      return generate_agent_no
    end
    return agent_no
  end

  # 生成用户编号
  def self.generate_user_no(agent)
    # 把唯一性验证交给 User validate
    if agent.no.blank?
      agent.no = generate_agent_no
      agent.save!
    end
    user_no = agent.no + CodeFormat.get_rand_number(4)
    if User.find_by_no(user_no).present?
      return generate_user_no(agent)
    end
    return user_no
  end

  def self.update_by_params(params)
    current_user = params[:user]
    agent = nil
    response = Response.rescue do |res|
      Agent.transaction do
        agent_id = params[:agent_id]
        res.raise_error(I18n.t("activerecord.errors.missing_required")) if agent_id.blank?
        update_params = params.require(:agent).permit!

        agent = Agent.find_by_id(agent_id)
        res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?

        if params[:address].present?
          begin
            address_params = params.require(:address).permit!
          end
          address = agent.address

          if address.present?
            address.update_attributes!(address_params)
          else
            address_params.merge!({ owner_id: agent.id, owner_type: "Agent" })
            address = Address.new(address_params).save!
          end
        end

        files = params[:files]
        if files.present?
          attachment_group = agent.attachment_group
          attachment_group = AttachmentGroup.create!(resource: agent, operator: current_user, catalog_type: AttachmentGroup::CatalogType::AGENT) if attachment_group.blank?
          Attachment.add_attachment(files, attachment_group, res) if files.present? && attachment_group.present?
        end

        enterprise_params = params[:enterprise]
        enterprise = agent.enterprise

        if enterprise_params.present?
          #当前公司为子公司，设置其母公司
          if enterprise_params[:parent_company_id].present?
            #如果之前为母公司，将其子公司设置为默认的母公司
            if enterprise.children.present?
              enterprise.children.each do |sub|
                sub.update(parent_id: nil)
              end
            end
            parent_id = Agent.find(enterprise_params[:parent_company_id]).enterprise.id
            enterprise.update(parent_id: parent_id)
            #当前公司为母公司，设置其子公司
          elsif enterprise_params[:subsidiary_company_ids].present?
            #若当前公司之前为子公司，将其parent_id设为空
            if enterprise.parent.present?
              enterprise.update(parent_id: nil)
            end
            #清空当前母公司所有子公司
            if enterprise.children.present?
              enterprise.children.each do |sub|
                sub.update(parent_id: nil)
              end
            end
            subsidiary_companies = Array.new
            enterprise_params[:subsidiary_company_ids].each do |sub_id|
              sub_com = Agent.find(sub_id).enterprise
              #如果子公司之前为母公司，将其子公司设置为默认的母公司
              if sub_com.children.present?
                sub_com.children.each do |sub|
                  sub.update(parent_id: nil)
                end
              end

              subsidiary_companies << sub_com
            end
            enterprise.add_child subsidiary_companies
            # 公司性质为母公司且没有选择子公司
          elsif enterprise_params[:subsidiary_company_ids] == []
            # 有附属子公司要将其子公司设置为默认的母公司
            if enterprise.children.present?
              enterprise.children.each do |sub|
                sub.update(parent_id: nil)
              end
            end
            enterprise.update(parent_id: nil)
          else
            res.raise_error("数据类型错误")
          end
        else
          # FIXME: 如果是母公司，并且传递的附属子公司为空
          if enterprise.children.present?
            enterprise.children.each do |child|
              child.update!(parent_id: nil)
            end
          end
          # FIXME: 子公司更改为母公司
          enterprise.update!(parent_id: nil) if enterprise.parent_id.present?
        end

        # # FIXME: 这里需要注意，当从大代理设置为小代理的时候，需要删除原先关联的大代理咨询顾问对象
        # if agent.agent_category.in?(Agent::AgentCategory::SENIOR_SHORE) && update_params[:agent_category] == Agent::AgentCategory::FRESH_AGENT
        #   agent.agent_users.each(&:destroy!)
        #   # FIXME: 如果是小代理转换为大代理的时候需要把原先关联的咨询顾问删除  agent.counsellor_id
        # elsif agent.agent_category == Agent::AgentCategory::FRESH_AGENT && update_params[:agent_category].in?(Agent::AgentCategory::SENIOR_SHORE)
        #   update_params.merge!(counsellor_id: nil)
        # end

        agent.update!(update_params)

        #创建账户
        if params[:contract].present?
          enterprise = agent&.enterprise
          agent_params = params[:agent]
          contract_params = params[:contract]
          user_status = (agent_params[:initial_account_status] == "open") ? User::UserStatus::ACTIVE : User::UserStatus::INVALID
          password = SecureRandom.base58(8)
          # 生成用户编号
          user_no = generate_user_no(agent)

          user = agent.users.where("users.email = '#{contract_params[:email]}' or users.phone = '#{contract_params[:phone]}'").first
          unless user
            user = User.new(
                {
                    username: contract_params[:email],
                    gender: "male",
                    phone: contract_params[:phone],
                    email: contract_params[:email],
                    status: user_status,
                    password: password,
                    create_user_id: params[:user].id,
                    post: "",
                    no: user_no,
                    real_name: contract_params[:contractor],
                    number_attribution: contract_params[:number_attribution],
                }
            )
            begin
              user.save!

              # FIXME: - 这里需要将address也关联到用户对应的address上面去
              address ||= agent.address

              user_address_params = address.attributes.except!("id", "owner_id", "owner_type", "created_at", "deleted_at", "updated_at")
              user_address_params.merge!("owner_id" => user.id, "owner_type" => User.name)
              user_address = Address.create!(user_address_params)

              user.update!(address_id: user_address.id)
            rescue => e
              res.raise_error(e.message)
            end
          end

          # 将新增用户添加至工作流
          begin
            AtyunWorkflow::WorkFlow.new.synch_user({ id: user.id.to_s, firstName: user.username, lastName: user.username, email: user.email, password: "123456" })
          rescue => e
            res.raise_error("工作流异常 - #{e}")
          end

          # 已统一改为代理管理员
          role_name = Role::Name::AGENT_ADMIN

          role = Role.find_by_name(role_name)

          res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if role.blank?

          #分配角色
          UserRole.create!(user_id: user.id, role_id: role.id)

          # 创建员工
          _employee = Employee.create!({ enterprise_id: enterprise.id, user_id: user.id, status: Employee::Status::WORKING })

          log "查看结果33333 - #{[agent_params[:initial_account_status] == "open", params[:contract].present?, !agent.is_meijia]}"

          if agent_params[:initial_account_status] == "open" && params[:contract].present? && !agent.is_meijia
            # pm16887 抄送给市场经理(manager)
            manager_email = agent&.manager&.email || nil

            cc_emails, _, _ = Student.relation_agent_emails(agent.id)

            to_emails = ([contract_params[:email], manager_email] | cc_emails).compact

            if manager_email
              vars = ({ "to" => to_emails, "sub" => { "%phone%" => [contract_params[:phone], contract_params[:phone]], "%email%" => [contract_params[:email], contract_params[:email]], "%password%" => [password, password] } })
            else
              vars = ({ "to" => to_emails, "sub" => { "%phone%" => [contract_params[:phone]], "%email%" => [contract_params[:email]], "%password%" => [password] } })
            end

            AtyunEmail::Providers::Sendcloud.send_email({ xsmtpapi: vars, :templateInvokeName => "create_aa_account" }, :allwin, {}) if Agent.is_send_email?(to_emails)

            # 发送手机短信
            params = { phone: contract_params[:phone], content: { phone: contract_params[:phone], email: contract_params[:email], password: password }, template_id: "6107", msg_type: 0 }
            if is_send_sms?(contract_params[:phone])
              sms_res = AtyunSms.send_sms(:SendCloud, params, AtyunSmsSetting.sendcloud)
              # if sms_res.present?
              #   res.message = sms_res["message"]
              #
              #   if sms_res["statusCode"]&.to_s != Response::Code::SMS_SUCCESS && contract_params[:number_attribution] == "china"
              #     res.raise_error("短信发送失败")
              #   end
              # end
            end
          end
        end

        if params[:contract].present? && contract_params[:id].present?
          # TODO: - 这里有点奇怪， 传递进来的合同关联的代理应该就是当前修改的代理 - 代码可以进行如下修改
          # contract = Contract.find(contract_params[:id])
          # TimeRecord.new(owner: contract.agent, approver: user, extra: {creator: current_user.real_name}, content: "创建了新的合同信息")
          TimeRecord.create!(owner: agent, approver: user, exrra: { creator: current_user.real_name }, content: "创建了新的合同信息")
        end
      end
    end

    agent.contracts.destroy_all if response.code == "50000"

    return response, agent
  end

  def self.show_agent(params)
    basic_info = nil
    financial_info = nil
    agent = nil
    response = Response.rescue do |res|
      user = params[:user]
      agent = user.get_agent
      res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?

      basic_info = agent.format_basic_info
      financial_info = agent.format_financial_info
    end
    [response, basic_info, financial_info, agent]
  end

  def self.account(params)
    response = Response.rescue do |res|
      agent_ids = params[:agent_ids]
      user = params[:user]

      agents = Agent.where(id: agent_ids)

      agents.each do |agent|
        if agent.initial_account_status == "close"
          agent.update!(initial_account_status: Agent::InitialAccountStatus::OPEN)
          # password = CodeFormat.get_rand_agent_account_password(6, 12) # FIXME: 多余
          # 发送新增帐号通知邮件
          users = agent.users
          # pm16887 邮件抄送市场经理
          manager_email = agent&.manager&.email || nil
          users.each do |user|
            user.status = User::UserStatus::ACTIVE
            password = SecureRandom.base58(8)
            user.password = password
            user.save!
            vars = ({ "to" => [user.email, manager_email], "sub" => { "%phone%" => [user.phone, user.phone], "%email%" => [user.email, user.email], "%password%" => [password, password] } })
            AtyunEmail::Providers::Sendcloud.send_email({ xsmtpapi: vars, :templateInvokeName => "create_aa_account" }, :allwin, {}) if is_send_email?([user.email, manager_email])

            # 发送手机短信
            params = { phone: user.phone, content: { phone: user.phone, email: user.email, password: password }, template_id: "6107", msg_type: 0 }
            _sms_res = AtyunSms.send_sms(:SendCloud, params, AtyunSmsSetting.sendcloud) if is_send_sms?(user.phone)
          end
        else
          res.raise_error(I18n.t("activerecord.errors.operation_not_performed"))
        end
      end
    end
    return response
  end

  def self.query_agent(params)
    users = nil
    agent = nil
    enterprise = nil

    response = Response.rescue do |res|
      page = params[:page] || 1
      per = params[:per] || 10
      res.raise_error(I18n.t("activerecord.errors.missing_required")) unless validate_all_present?(params[:agent_id])
      agent = Agent.eager_load(:new_popedom, :former_popedom, :counsellor, :manager, :developer,
                               :sales_manager, :follow_up_counsellor,
                               address: [:country, :province, :city, :district], attachment_group: :attachments)
                  .where(id: params[:agent_id]).first
      users = User.left_joins(:agents).where(agents: { id: params[:agent_id] })
                  .where("users.real_name like ?", "%#{params[:real_name]}%")
                  .order("users.created_at desc").distinct.page(page).per(per)
      enterprise = Enterprise.find_by_resource_id(params[:agent_id])
    end

    [response, agent, users, enterprise]
  end

  # 分页
  # @param  data_array [Array, #read]  需要分页显示的数组对象
  # @param  total_count [int] 数组总条数
  # @param  page [int] 当前页数
  # @param  per [int] 一页有多少笔纪录
  # @return Array  被处理后的分页对象
  def self.paginate_array(data_array, total_count, page, per)
    Kaminari.paginate_array(data_array, total_count: total_count).page(page).per(per)
  end

  # def self.flush
  #   Agent.transaction do
  #     user = User.find 34
  #     Agent.all.each do |agent|
  #       agent.update!(counsellor_id: user.id)
  #     end
  #   end
  # end

  def format_basic_info
    # TODO zhouxin 所在地 地址 附件
    options = {
        temp_full_name_cn: self.temp_full_name_cn,
        name_cn: self.name_cn,
        abbreviant: self.abbreviant,
        name_en: self.name_en,
        agent_type: self.agent_type,
        foreign_name: self.foreign_name,
        id: self.id,
        country_id: self.address&.country&.id,
        province_id: self.address&.province&.id,
        city_id: self.address&.city&.id,
        country_name: self.address&.country&.name,
        province_name: self.address&.province&.name,
        city_name: self.address&.city&.name,
        district_name: self.address&.district&.name,
        detail_address: self.address&.detail_address,
        phone: self.phone,
        fax: self.fax,
        is_real: self.is_real,
        remark: self.remark,
        files: Attachment.where(attachment_group_id: self.attachment_group&.id),
    }
    options
  end

  def format_financial_info
    options = {
        financial_contact: {
            name: self.financial_contact&.name,
            email: self.financial_contact&.email,
            phone: self.financial_contact&.phone,
        },
        bank_accounts: {
            account_name: self.bank_account&.account_name,
            name: self.bank_account&.name,
            no: self.bank_account&.no,
            opening_bank_name: self.bank_account&.opening_bank_name,
            swift_code: self.bank_account&.swift_code,
            intermediary_bank_name: self.bank_account&.intermediary_bank_name,
            intermediary_bank_swift_code: self.bank_account&.intermediary_bank_swift_code,
        },
    }
    options
  end

  def self.create_account(res, user, agent)

    #模拟创建公司
    enterprise = Enterprise.create(resource: agent, name: agent.name_cn)

    #创建账户
    password = SecureRandom.base58(8)
    # 生成用户编号
    user_no = generate_user_no(agent)

    #根据合同获取email 和phone
    contract = agent.contracts.last

    # 判断User是否已经存在
    user_phone = User.find_by_phone(contract.phone)
    res.raise_error(I18n.t("activerecord.errors.phone_already_registered")) if user_phone.present?

    user_email = User.find_by_email(contract.email)
    res.raise_error(I18n.t("activerecord.errors.email_already_registered")) if user_email.present?

    user = User.new(
        {
            username: "#{agent.abbreviant}",
            gender: "male",
            phone: contract.phone,
            email: contract.email,
            status: User::UserStatus::ACTIVE,
            password: password,
            create_user_id: user.id,
            post: "",
            no: user_no,
        }
    )

    begin
      user.save!
    rescue => e
      res.raise_error(I18n.t("activerecord.errors.operation_not_performed"))
    end

    #机构代理角色
    # if agent_params[:agent_type] == Agent::AgentType::ENTERPRISE
    #   role_name = Role::Name::ORGANIZATION_AGENT_ADMIN
    # else
    #   role_name = Role::Name::PERSONAL_AGENT
    # end
    # 已统一改为代理管理员
    role_name = Role::Name::AGENT_ADMIN

    role = Role.find_by_name(role_name)

    res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if role.blank?

    #分配角色
    UserRole.create!(user_id: user.id, role_id: role.id)

    # 创建员工
    employee = Employee.create({ enterprise_id: enterprise.id, user_id: user.id })

    # 将新增用户添加至工作流----跟周家成沟通过，activi里面统一使用当前user.id
    begin
      AtyunWorkflow::WorkFlow.new.synch_user({ id: user.id.to_s, firstName: user.username, lastName: user.username, email: user.email, password: "123456" })
    rescue => e
      res.raise_error("工作流异常 - #{e}")
    end

    # 发送新增帐号通知邮件
    vars = ({ "to" => [contract.email], "sub" => { "%phone%" => [contract.phone], "%email%" => [contract.email], "%password%" => [password] } })
    AtyunEmail::Providers::Sendcloud.send_email({ xsmtpapi: vars, :templateInvokeName => "create_aa_account" }, :allwin, {}) if is_send_email?(contract.email)
  end

  def self.commission_infos(params)
    commission_infos = []
    response = Response.rescue do |res|
      agent_id = params[:agent_id]
      agent = Agent.find_by_id(agent_id)
      res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?
      search_params = {
          owner_id: agent.id, owner_type: agent.class,
      }
      commission_infos = CommissionInfo.search_by_params(search_params).order(settle_end_date: :asc)
    end
    return response, commission_infos
  end

  def self.check_information(params)
    user = nil
    response = Response.rescue do |res|
      res.raise_error(I18n.t("activerecord.errors.missing_required")) if params[:email].blank? || params[:phone].blank?

      # 判断User是否已经存在
      user = User.find_by_phone(params[:phone])
      res.raise_error(I18n.t("activerecord.errors.phone_already_registered")) if user.present?

      user = User.find_by_email(params[:email])
      res.raise_error(I18n.t("activerecord.errors.email_already_registered")) if user.present?
    end
    [response, user]
  end

  def self.company_info(params)
    basic_info = nil
    financial_info = nil
    agent = nil
    response = Response.rescue do |res|
      user = params[:user]
      agent = user.get_agent
      res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?
      basic_info = agent.format_basic_info
      financial_info = agent.format_financial_info
    end
    [response, basic_info, financial_info, agent]
  end

  def self.update_company_info(params)
    basic_info = nil
    agent = nil
    response = Response.rescue do |res|
      transaction do
        basic_info = params.require(:basic_info).permit!
        res.raise_error(I18n.t("activerecord.errors.missing_required")) if basic_info.blank?
        user = params[:user]
        agent = user.get_agent
        res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if agent.blank?
        basic_info = params[:basic_info]

        basic_info_param = {
            name_en: basic_info[:name_en],
            foreign_name: basic_info[:foreign_name],
            agent_type: basic_info[:agent_type],
            phone: basic_info[:phone],
            fax: basic_info[:fax],
            is_real: basic_info[:is_real],
            remark: basic_info[:remark],
        }

        address_params = {
            country_id: basic_info.delete(:country_id),
            province_id: basic_info.delete(:province_id),
            city_id: basic_info.delete(:city_id),
            detail_address: basic_info.delete(:detail_address),
        }

        agent.update!(basic_info_param)

        address = agent.address
        if address.present?
          address.update_attributes!(address_params)
        else
          if address_params[:country_id].present? && address_params[:province_id].present?
            address_params.merge!({ owner_id: agent.id, owner_type: "Agent" })
            Address.create!(address_params)
          end
        end

        #附件
        company_files = params[:company_files]
        if company_files.present?
          company_group = agent.attachment_group
          if company_group.blank?
            company_group = AttachmentGroup.create!(resource: agent, catalog_type: AttachmentGroup::CatalogType::Company)
          end

          Attachment.add_attachment(company_files, company_group, res)
        end

        basic_info = agent.format_basic_info
      end
    end
    [response, basic_info, agent]
  end

  # 输入初始日期 计算当前代理在这个日期范围内的结案数
  def get_specified_date_settle_num(start_date, end_date)
    params = {
        'between_apply_forms.closure_time': "#{start_date} #{end_date}",
        'agents.id': self.id,
        'apply_forms.status': ApplyForm::Status::CLOSURE,
        'apply_forms.contract_type': ApplyForm::ContractType::STUDY,
    }
    # if end_date == CommissionInfo::Special_Condition::END_2018
    #   params.merge!(
    #     'address_units.name': "澳大利亚",
    #     'address_units.unit_type': "Country",
    #   )
    # end
    ApplyForm.eager_load(school_course_infos: :address_unit, student: :agent).search_by_params(params).count
  end

  # 根据指定日期更新当前代理的年度档位
  def calculate_agent_year_rate_by_specified_date(start_date, end_date)
    if Date.today >= start_date && Date.today <= end_date
      year_rate = get_agent_year_rate_not_update(start_date, end_date)
      settle_num = self.get_specified_date_settle_num(start_date, end_date)
      forecast_num = CommissionInfo.get_forecast_num(settle_num, start_date, end_date)
      tx = CommissionInfo.get_tx_by_settle_num(forecast_num)
      chosen_commission_info = self.commission_infos.where(settle_start_date: start_date.to_date, settle_end_date: end_date.to_date).first
      chosen_commission_info.update!(year_rate: year_rate, closure_num: settle_num, tx: tx) if chosen_commission_info.present? && year_rate.present? && settle_num.present?
      year_rate
    else
      self.commission_infos.where("settle_start_date <= ? and  settle_end_date >= ?", end_date, start_date).first&.year_rate
    end
  end

  def get_agent_year_rate_not_update(start_date, end_date)
    CommissionRule.get_year_rate_by_settle_num self.get_specified_date_settle_num(start_date, end_date)
  end

  # 每年7月1号自动创建新的合同版本 如2017年7月1号创建合同版本201707，预估佣金比例为16年的年度佣金比例
  def self.create_contract_automatically
    year = Time.now.year
    response = Response.rescue do |res|
      # agent_last = Agent.first
      # log agent_last.commission_infos
      Agent.transaction do
        agents = Agent.all
        agents.each do |agent|
          commission_info_last = agent&.commission_infos&.last
          if commission_info_last.present?
            commission_info = CommissionInfo.new(settle_start_date: "#{year}-07-01", settle_end_date: "#{year + 1}-06-30", is_special: commission_info_last.is_special, special_rate: commission_info_last.special_rate, closure_num: 0, contract_version: "201607", owner: agent, forecast_rate: commission_info_last.year_rate, year_rate: 0.00, special_settle_rule: commission_info_last.special_settle_rule, subject_id: commission_info_last.subject_id)
          else
            limited = DataDictionary.where(value: 'AAedu International Limited').first
            commission_info = CommissionInfo.new(settle_start_date: "#{year}-07-01", settle_end_date: "#{year + 1}-06-30", is_special: false, special_rate: 0.0, closure_num: 0, contract_version: "201607", owner: agent, forecast_rate: 0.00, year_rate: 0.00, subject_id: limited.id)
          end
          log commission_info.contract_version
          commission_info.save!
        end
      end
    end
    [response]
  end

  # 获取代理发起申请费相关数据
  def self.get_initiate_application_fee_by_params(params)
    application_fee_params = nil
    response = Response.rescue do |res|
      Agent.transaction do
        plan_id, student_id = params.values_at(:plan_id, :student_id)
        res.raise_error(I18n.t("activerecord.errors.missing_required")) unless validate_all_present?(plan_id, student_id)

        plan = Plan.find_by_id plan_id
        res.raise_error(I18n.t("activerecord.errors.operation_not_performed")) if plan.work_flow_status == Plan::WorkFlowStatus::FINISHED
        res.raise_error(I18n.t("activerecord.errors.operation_not_performed")) if plan.school_course_infos.find { |x| ([x.agent_course_status, x.manager_course_status] & SchoolCourseInfo::CourseStatus::EXPIRED).present? }.present?

        student = Student.find_by_id student_id
        agent = student.agent
        main_school_course_info = plan.school_course_infos.where(is_main_course: true).take
        res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if main_school_course_info.blank?
        main_school = main_school_course_info.school
        res.raise_error(I18n.t("activerecord.errors.data_not_exist")) if main_school.blank?

        # 根据国家获取 币种
        country = main_school.country
        currency = Currency.find_by_country_id country.id if country.present?

        main_course_name = main_school_course_info&.professions&.first&.course_name_en || main_school_course_info&.course_name_en
        # 是否存在未完成支付的订单
        is_have_not_complete_application_fee = false
        is_free_application_fee = false
        # 是否存在已经支付完成的订单
        is_have_complete_application_fee = false
        is_need_application_fee = main_school&.is_need_application_fee || false

        # 只需要根据订单的支付状态获取未支付完成的订单就可以（这里包括线下未支付）
        no_pay_order = Order.left_joins(:order_plan_audit).where(status: Order::Status::NotPay).where(order_plan_audits: { plan_id: plan.id }).distinct&.take
        is_have_not_complete_application_fee = true if no_pay_order.present?

        pay_orders = Order.left_joins(:order_plan_audit).where(status: Order::Status::PaySuccess).where(order_plan_audits: { plan_id: plan.id }).distinct
        is_have_complete_application_fee = true if pay_orders.present?

        application_fee_params = {
            is_need_application_fee: is_need_application_fee,
            can_pay_application_fee_by_aa: main_school&.can_pay_application_fee_by_aa || "",
            school_name: main_school&.name_en, student_awid: student.awid,
            student_name: student.name, agent_id: agent.id, plan_id: plan.id,
            student_id: student.id, agent_name_en: agent&.abbreviant || agent&.name_en,
            main_school_course_info_id: main_school_course_info.id, currency_code: currency.code,
            is_have_not_complete_application_fee: is_have_not_complete_application_fee,
            is_free_application_fee: is_free_application_fee, pay_channel: no_pay_order&.pay_channel,
            pay_way: no_pay_order&.pay_way, school_id: main_school.id, course_name_en: main_course_name,
            application_fee: main_school&.application_fee, is_have_complete_application_fee: is_have_complete_application_fee,
        }
      end
    end

    return response, application_fee_params
  end

  # 发起代理支付申请费
  def self.initiate_application_fee_by_params(params)
    application_fee_order = nil
    response = Response.rescue do |res|
      Agent.transaction do
        # 需要再次发送系统消息提示代理支付申请费 - agent_confirm_send_message
        application_fee_params, user, agent_confirm_send_message, files = params.values_at(:application_fee_params, :user, :agent_confirm_send_message, :files)
        user = User.find_by_id user.id
        plan = Plan.find_by_id application_fee_params[:plan_id]
        process_work = plan.process_works.first
        main_school_course_info = SchoolCourseInfo.find_by_id application_fee_params[:main_school_course_info_id]
        main_school = School.find_by_id application_fee_params[:school_id]

        # 根据国家获取 币种
        currency_code = application_fee_params[:currency_code]
        if currency_code.blank?
          country = main_school.country
          currency_code = Currency.find_by_country_id(country.id)&.code if country.present?
        end

        student = Student.find_by_id application_fee_params[:student_id]
        assigned_user = student.assigned_user
        money = format("%.2f", application_fee_params[:application_fee]).to_d
        # 备注
        note = application_fee_params[:note]
        # 是否需要支付申请费
        is_need_application_fee = application_fee_params[:is_need_application_fee]
        # 是否免申请费 - 默认是false, 根据支付方式判断为true
        is_free_application_fee = false
        # 是否能支付申请费
        can_pay_application_fee_by_aa = application_fee_params[:can_pay_application_fee_by_aa]
        # 是否存在未完成支付的订单
        is_have_not_complete_application_fee = application_fee_params[:is_have_not_complete_application_fee]
        # 是否存在已经支付完成的订单
        is_have_complete_application_fee = application_fee_params[:is_have_complete_application_fee]

        # 支付方式，支付渠道
        pay_channel, pay_way = application_fee_params.values_at(:pay_channel, :pay_way)

        res.raise_error(I18n.t("activerecord.errors.missing_required")) unless validate_all_present?(plan, main_school_course_info, main_school, student, money, process_work, pay_channel, pay_way, currency_code)

        is_free_application_fee = true if pay_way == Order::PayWay::FreeApplicationFee

        res.raise_error(I18n.t("activerecord.errors.missing_required")) if is_need_application_fee.nil? || is_free_application_fee.nil? || can_pay_application_fee_by_aa.nil? || is_have_not_complete_application_fee.nil? || is_have_complete_application_fee.nil?

        res.raise_error(I18n.t("activerecord.errors.operation_not_performed")) unless is_need_application_fee == true

        # 没申请过申请费
        if is_have_not_complete_application_fee == false
          big_course_category = main_school_course_info.big_course_category
          if BigCourseCategory::NameEn::NO_PROFESSION.include?(big_course_category.name_en)
            professions = []
          else
            professions = main_school_course_info.professions
            professions = professions.map { |x| { course_name_en: x.course_name_en, course_code: x.course_code, course_pattern: x.course_pattern } }
          end

          # 这里现在是设置为都是 no_pay
          audit_form = AuditForm.create!({
                                             status: AuditForm::Status::NO_PAY, audit_form_type: AuditForm::AuditFormType::APPLICATION_FEE,
                                             process_id: process_work.process_id, resource: process_work, approver: user, note: note,
                                         })

          bank_account = main_school&.bank_accounts&.first
          create_order_options = {
              user_id: student.assigned_id,
              student_id: student.id,
              detail_infos: [
                  {
                      school_course_info_id: main_school_course_info.id,
                      student_awid: student.awid,
                      pay_fee: money,
                      include_insurance_fee: "0.00",
                      currency: currency_code,
                      professions: professions,
                      student_offer_number: main_school_course_info&.student_offer_number || "",
                      bank_account_id: bank_account&.id || "",
                  },
              ],
              extra: {
                  student_info: {
                      cn_name: student&.name,
                      ID_Card: student&.id_number,
                      email: student&.email,
                      first_name: student&.family_name,
                      last_name: student&.given_name,
                  },
              },
              order_type: Order::OrderType::ApplicationFee,
              plan_id: plan.id,
              audit_form_id: audit_form.id,
              pay_way: pay_way,
              pay_channel: pay_channel,
              currency: currency_code,
          }

          res_order, application_fee_order = Order.create_or_update_by_params(create_order_options)
          res.raise_error(res_order.message) unless res_order.code == Response::Code::SUCCESS

          # 根据PM需求适配
          audit_form.update!(extra: { order_id: application_fee_order.id, pay_way: pay_way, pay_channel: pay_channel })
        end

        if is_free_application_fee == true && is_have_not_complete_application_fee == false
          application_fee_order&.update!({
                                             status: Order::Status::Completed, note: "免申请费", total_price: 0.00,
                                             pay_way: Order::PayWay::FreeApplicationFee, pay_time: Time.now,
                                             pay_channel: Order::PayChannel::Offline,
                                         })
          time_record_content = "发起代理支付申请费，支付方式：免申请费，申请院校：#{main_school&.name_en || main_school&.full_name_en}, 课程名称：#{main_school_course_info.professions.where(seq: 1)&.take&.course_name_en || main_school_course_info&.course_name_en}#{note.present? ? ", 备注：#{note}" : "."}"
        elsif is_free_application_fee == false && is_have_not_complete_application_fee == false
          # 待办任务新建 - 申请费递交 - 系统代办创建回调 after_create 已经发送邮箱
          if Order::PayWay::ONLINE_PAY.include?(pay_way)
            # TODO: - PM - 20626 - 给代理发送的待办邮件，邮件标题需要根据不同的待办类型进行修改。
            agency_email_total_extra = { agency_email_total: "亲~可以支付申请费啦！", agency_email_total_2: "#{main_school.name_en || main_school.full_name_en}" }
            _agency_matter_application = AgencyMatter.create_by_params(res, { process_work: process_work, to: student.assigned_user, from: user, resource: plan,
                                                                              jump_owner: student, name_en: AuditForm::AuditFormType::APPLICATION_FEE,
                                                                              jump_type: AgencyMatter::JumpType::ORDER_TO_APPLICATION_ORDER_PAY, extra: agency_email_total_extra })
            # else
            #   content = "#{student.name}的申请 #{main_school&.name_en || main_school&.full_name_en}, #{AuditForm::AuditFormType.get_desc_by_value(AuditForm::AuditFormType::APPLICATION_FEE)}"
            #   vars = ({"to" => [assigned_user.email], "sub" => {"%content%" => [content], "%fee%" => ['如您已发送凭证，请忽略本消息'], "%student_name%" => [student.name] }})
            #   # 发送邮件
            #   AtyunEmail::Providers::Sendcloud.send_email({xsmtpapi: vars, :templateInvokeName => 'fee_agency_matter'}, :allwin, {}) if AgencyMatter.is_send_email?
            # end

            # 代理端代办状态
            school_course_status_hash = { agent_next_status: SchoolCourseInfo::AuditFormStatus::APPLICATION_FEE }
            process_work.change_course_or_change_status(res, school_course_status_hash)

            # 我的消息
            # 学生代理人
            message_content = "【申请费订单】学生：#{student.name} 申请院校：#{main_school&.name_en || main_school&.full_name_en}的申请费订单：已创建，请知晓."
            jump_type = Message::JumpType::ORDER_TO_APPLICATION_ORDER_PAY
            AuditForm.v2_send_internal_message({ to_id: student.assigned_id, message_type: Message::MessageType::ORDER_STATUS, content: message_content,
                                                 extra: nil, resource_id: application_fee_order.id, resource_type: "Order", jump_type: jump_type, jump_owner_id: student.id, jump_owner_type: "Student" })
          else
            # 如果是提供信用卡  这里订单的状态更改为  未提供信用卡
            application_fee_order.update!(status: Order::Status::UnProvideCreditCard) if application_fee_order.pay_way == Order::PayWay::ProvideVisaInfo

            if (application_fee_order.pay_way == Order::PayWay::SpecifyAccount || application_fee_order.pay_way == Order::PayWay::SpecifyForeignAccount) && files.present?
              attachment_group = AttachmentGroup.find_or_create_by!(catalog_type: AttachmentGroup::CatalogType::Voucher, resource: audit_form, data_source: "支付申请费凭证")
              files.each_with_index do |file_dict, i|
                file_params = Attachment.check_file_params(file_dict, res)
                # 生成审批单附件
                attachment = Attachment.new(file_params)
                attachment.plan_list = "plan_#{plan.id}" # 关联当前方法
                attachment.attachment_group_id = attachment_group.id
                attachment.status = Attachment::Status::Show
                attachment.data_source = Attachment::DataSource::INITIATE_AGENT_PAYMENT_APPLICATION_FEE
                attachment.save!
              end
            end
          end

          time_record_content = "发起代理支付申请费，支付方式：#{Order::PayWay.get_desc_by_value(pay_way)}，申请院校：#{main_school&.name_en || main_school&.full_name_en}, 课程名称：#{main_school_course_info.professions.where(seq: 1)&.take&.course_name_en || main_school_course_info&.course_name_en}, 总应付金额：#{money} #{application_fee_order&.currency}#{note.present? ? ", 备注：#{note}" : "."}"
        elsif agent_confirm_send_message == true && is_have_not_complete_application_fee == true
          application_fee_order = Order.left_joins(:order_plan_audit).where(order_plan_audits: { plan_id: plan.id }).distinct.take
          # 学生代理人
          message_content = "【申请费订单】学生：#{student.name} 申请院校：#{main_school&.name_en || main_school&.full_name_en}的申请费订单：已创建，请知晓."
          jump_type = Message::JumpType::ORDER_TO_APPLICATION_ORDER_PAY
          AuditForm.v2_send_internal_message({ to_id: student.assigned_id, message_type: Message::MessageType::ORDER_STATUS, content: message_content,
                                               extra: nil, resource_id: application_fee_order.id, resource_type: "Order", jump_type: jump_type, jump_owner_id: student.id, jump_owner_type: "Student" })

          content = "#{student.name}的申请 #{main_school&.name_en || main_school&.full_name_en}, #{AuditForm::AuditFormType.get_desc_by_value(AuditForm::AuditFormType::APPLICATION_FEE)}"
          vars = ({ "to" => [assigned_user.email], "sub" => { "%content%" => [content], "%fee%" => ["如您已发送凭证，请忽略本消息"], "%student_name%" => [student.name] } })

          # 发送邮件
          AtyunEmail::Providers::Sendcloud.send_email({ xsmtpapi: vars, :templateInvokeName => "fee_agency_matter" }, :allwin, {}) if AgencyMatter.is_send_email?(assigned_user.email)
        end

        AuditForm.create_time_record(res, process_work, user, "运营端", "发起代理支付申请费", audit_form, AuditForm::Platform::ManagerPlatform, time_record_content) if is_have_not_complete_application_fee == false
      end
    end

    return response, application_fee_order
  end

  def self.get_agent_enterprise(params)
    agents = nil

    response = Response.rescue do |res|
      res.raise_error(I18n.t("activerecord.errors.missing_required")) if params[:enterprise_type].blank?
      enterprise_type = params[:enterprise_type]
      search_param = params[:search] || {}
      page = params[:page] || 1
      per = params[:per] || 50
      #选择子公司时，可以选择系统所有的代理机构
      if enterprise_type == Enterprise::EnterpriseType::SUBSIDIARY
        agents = Agent.search_by_params(search_param).order(created_at: :desc).select(:id, :abbreviant).page(page).per(per)
        #选择母公司是，可以选择公司类型为母公司的代理机构
      elsif enterprise_type == Enterprise::EnterpriseType::PARENT
        agents = Agent.search_by_params(search_param).joins(:enterprise)
                     .where(enterprises: { parent_id: nil }).order(created_at: :desc).select(:id, :abbreviant).page(page).per(per)
      else
        res.raise_error(I18n.t("activerecord.errors.data_type_error"))
      end
    end

    return response, agents
  end

  # 根据代理类型得到代理信息 级联菜单 只是暂时使用
  def self.get_by_agent_type(params)
    agents = nil
    response = Response.rescue do |_res|
      page = params[:page] || 1
      per = params[:per] || 10
      search_params = params[:search] || {}
      agents = Agent.search_by_params(search_params).order(id: :asc)

      agents = agents.page(page).per(per) if params[:page].present? && params[:per].present?
    end

    [response, agents]
  end


  def self.send_agent_task(role_name, export_data, sheet_row_columns, to_emails, from_email, subject)
    show_string = ''
    export_data.each do |key_name, value_arr|
      show_string += "<p>#{key_name} (#{role_name}) 名下学生清单: </p>"
      show_string += "<p class='header-total'>#{sheet_row_columns.join}</p>"
      value_arr.each do |dict|
        if role_name == '咨询顾问'
          show_string += "<p>#{[dict['student_awid'] || "", dict['student_name'] || "", dict['tuition_plan_date'] || "", SchoolCourseInfo::CourseStatus.get_desc_by_value(dict['course_status']) || ""].map { |x| Agent.stitching_character_length(x) }.join}</p>"
        elsif role_name == '材料顾问'
          show_string += "<p>#{[dict['student_awid'] || "", dict['student_name'] || "", dict['tuition_plan_date'] || "", SchoolCourseInfo::CourseStatus.get_desc_by_value(dict['course_status']) || "", dict['material_content_check_date'] || ""].map { |x| Agent.stitching_character_length(x) }.join}</p>"
        else
          raise("暂不支持其他角色任务导出")
        end
      end

      # FIXME: 多添加一行分割线
      show_string += "<br/><br/>"
    end

    # FIXME: 发送邮件
    content = "<div class='send-task'>
                  #{show_string}
                  <p>本邮件由系统自动发送，请勿回复</p>
              </div>"

    html = <<-HTML
#{content}
    HTML

    send_email_params = {
        content: html,
    }

    send_params = {
        to: to_emails,
        from: from_email || SendcloudSetting.allwin.from,
        template_path: UsersMailer::TEMPLATE_PATH,
        template_name: UsersMailer::TemplateName::SEND_AGENT_TIMING_TASK,
        subject: subject,
    }

    send_params.merge!(bcc: 'wuxianan@atyun.net') unless to_emails.include?('wuxianan@atyun.net')

    # 发送邮件
    send_email_response = UsersMailer.send_email(send_params, [], send_email_params).deliver_now!
    # 新建一个线程，删除临时文件里面的附近

    return send_email_response
  end

  def self.stitching_character_length(str, length = 25)
    if str.is_a?(Array)
      str.map! { |x| Agent.stitching_character_length(x) }
      return str
    else
      return (str + "&nbsp;" * 8) if str.length >= length

      (length - str.length).times { |_x| str += "&nbsp;" }

      return "<span>#{str}</span>"
    end
  end

  def self.get_search_result(agent_id, check_column)
    sql = "select student_name, student_awid, student_current_status, tuition_plan_date, course_status, counsellor_name,
            counsellor_email, custom_service_name, custom_service_email, material_content_check_date
              from (select distinct on (student_id,
                         plan_id) plans.id                         as plan_id,
                         students.name                             as student_name,
                         students.awid                             as student_awid,
                         (case
                            when students.current_status = 'active' then '已递交'
                            when students.current_status = 'draft' then '未递交'
                            else ''
                             end)                                  as student_current_status,
                         students.id                               as student_id,
                         COALESCE(to_char(plan_progress_summaries.tuition_plan_date, 'YYYY-MM-DD HH24:MI:SS'),
                                  '')                              AS tuition_plan_date,
                         COALESCE(to_char(plan_progress_summaries.material_content_check_date, 'YYYY-MM-DD HH24:MI:SS'),
                                  '')                              AS material_content_check_date,
                         school_course_infos.manager_course_status as course_status,
                         counsellors.real_name                     as counsellor_name,
                         counsellors.email                     as counsellor_email,
                         custom_services.real_name            as custom_service_name,
                         custom_services.email                as custom_service_email
                    from plans
                           inner join apply_forms on apply_forms.id = plans.apply_form_id and apply_forms.deleted_at is null and
                                                     apply_forms.status = 'waiting'
                           inner join users counsellors on counsellors.id = plans.counsellor_id and counsellors.deleted_at is null
                           inner join users custom_services on custom_services.id = plans.custom_service_id and custom_services.deleted_at is null
                           inner join students
                             on students.id = plans.owner_id and plans.owner_type = 'Student' and students.deleted_at is null
                           inner join agents on agents.id = students.agent_id and agents.deleted_at is null
                           inner join school_course_infos
                             on school_course_infos.plan_id = plans.id and school_course_infos.deleted_at is null
                           inner join plan_progress_summaries
                             on plan_progress_summaries.school_course_info_id = school_course_infos.id and
                                plan_progress_summaries.deleted_at is null
                    where plans.deleted_at is null and plans.work_flow_status = 'un_finished' and plans.apply_status = 'waiting'
                      and plans.created_at between '#{(Time.now - 1.months).strftime('%F %T')}' and '#{Time.now.strftime('%F %T')}'
                      and agents.id = #{agent_id}
                      and #{check_column == 'plan_check_time' ? "plan_progress_summaries.#{check_column} is null" : "plan_progress_summaries.#{check_column} is null and plan_progress_summaries.plan_check_time notnull"}
                    order by plan_id asc) temp_tables
              order by tuition_plan_date asc;"

    result = ActiveRecord::Base.connection.select_all(sql)

    return result
  end

  # 导入代理财务信息
  def self.import_financial_contact(params)
    response = Response.rescue do |res|

      user = User.where(id: params[:user].id).take

      file_path = Downloader.download_by_url(params[:file][:attachment_url])

      AgentFinancialContactV20181204Importer.import(file_path, params: { agent_id: params[:agent_id], res: res })

      agent = Agent.where(id: params[:agent_id]).last

      agent.solve_financial_attachment(user, [params[:file]], res)

    end
    return response
  end

  # 导出财务信息excel模板
  def self.export_financial_excel
    url = nil
    response = Response.rescue do |res|

      url = Attachment.where(data_source: Attachment::DataSource::AGENT_FINANCIAL_TEMPLATE).first&.attachment_url

    end
    return response, url
  end

  # 无签约代理邮件提醒
  def self.no_signing_warning
    response = Response.rescue do |_res|
      Agent.transaction do
        return unless HostSetting.env == 'dit' || HostSetting.env == 'prod'

        # 1. 获取TX档位的基础配置
        search_tx_params = {
            search: {
                "data_dictionary_categories.class_name" => "CommissionInfo",
                "data_dictionary_categories.attribute_name" => "Tx",
                "data_dictionaries.status" => "active",
                "order" => "data_dictionaries.seq ASC NULLS LAST"
            }
        }
        _res, tx_results = DataDictionary.query_by_params(search_tx_params)
        tx_results = tx_results.map { |x| x.slice(:id, :name, :value) }

        # 2. 获取代理数据字段关于有效性的数据获取
        search_validity_params = {
            search: {
                "data_dictionary_categories.class_name" => "Agent",
                "data_dictionary_categories.attribute_name" => "validity",
                "data_dictionaries.status" => "active",
                "order" => "data_dictionaries.seq ASC NULLS LAST",
                "data_dictionaries.name" => ['有效', '需判定']
            }
        }
        _res, validity_results = DataDictionary.query_by_params(search_validity_params)

        # 获取数据 - 这里需要分两步来进行获取 -
        # 1： T1  T2  T3   无档位
        # 搜索依据：代理有效性：有效，需判定，有效性判定岗位：市场经理， 上一财年Tx： T1  T2  T3  无档位

        # 2: T4
        # 搜索依据：代理有效性：有效，需判定，有效性判定岗位：市场经理， 上一财年Tx： T4

        # 3： 空白
        # 搜索依据：代理的建档日期（当前财年） 和 上一个财年Tx 为空白，有效性判定岗位：市场经理

        current_year = Time.now - 1.days
        y = (current_year.month > 7) ? 0 : 1
        current_year_strat = "#{(current_year - y.year).strftime("%Y")}-07-01"
        last_year_strat = "#{(current_year - (1 + y).year).strftime("%Y")}-07-01"

        country = AddressUnit.where(name: '澳大利亚', unit_type: 'Country').first

        search_one_params = {
            "commission_infos.settle_start_date" => last_year_strat,
            "t.manager_validity_id" => validity_results.ids,
            "commission_infos.tx" => CommissionInfo::Tx::NotBlank,
            # "commission_infos.settle_start_date" => Time.parse(current_year_strat) - 1.years
        }
        search_one_results = Agent.get_Tx_results(search_one_params)

        if search_one_results.present?
          search_one_results.each do |agent_info|
            current_tx = agent_info['tx']
            tx_result = tx_results.find { |x| x['name'] == current_tx }

            # FIXME: max_contract_date可能是空的情况
            temp_contract_date = Date.parse(agent_info['max_contract_date'].presence || agent_info['agent_created_at']) + 1.days


            # FIXME: 需要注意，这里比较特殊的地方是，不管新建的代理当前财年的预估档位
            # FIXME: 计算相隔的日期是否能被tx_result.value 余 0
            # FIXME: 特别需要注意的是 这里需要加 1 天，并且如果数据为 1 的时候不能当作除数进行计算，因为结果始终都是 1
            date_interval_count = (Date.parse(current_year.strftime('%F')) - temp_contract_date).to_i + 1

            next unless (date_interval_count > 1) && ((date_interval_count % tx_result['value'].to_i) == 0)

            # 发送邮件
            # 获取收件人信息 - 拼接数据
            to_email, agent, agent_manager = Student.relation_agent_emails(agent_info['id'])

            year_contract_volume_params = {
                "between_apply_forms.contract_date" => "#{(temp_contract_date - 1.years).strftime('%F')} #{(current_year - 1.years).strftime('%F')}",
                "agents.id" => agent_info['id'],
                "school_course_infos.country_id" => country.id
            }
            year_contract_volume = ApplyForm.joins(student: :agent, plans: :school_course_infos).search_by_params(year_contract_volume_params).distinct.count

            tx = agent.commission_infos.find_by(settle_start_date: Time.parse(current_year_strat) - 1.years)&.tx

            closure_count_params = {
                "apply_forms.status" => ApplyForm::Status::CLOSURE,
                "between_apply_forms.closure_time" => "#{temp_contract_date.strftime('%F')} #{current_year.strftime('%F')}",
                "agents.id" => agent_info['id'],
                "school_course_infos.country_id" => country.id
            }
            closure_count = ApplyForm.joins(student: :agent, plans: :school_course_infos).search_by_params(closure_count_params).distinct.count

            closure_count_volume_params = {
                "apply_forms.status" => ApplyForm::Status::CLOSURE,
                "between_apply_forms.closure_time" => "#{(temp_contract_date - 1.years).strftime('%F')} #{(current_year - 1.years).strftime('%F')}",
                "agents.id" => agent_info['id'],
                "school_course_infos.country_id" => country.id
            }
            closure_count_volume = ApplyForm.joins(student: :agent, plans: :school_course_infos).search_by_params(closure_count_volume_params).distinct.count

            closed_year_on_year = if closure_count_volume != 0
                                    ActiveSupport::NumberHelper.number_to_percentage((closure_count.to_f / closure_count_volume.to_f) * 100, precision: 2)
                                  else
                                    "无"
                                  end

            send_email_params = {
                no_signing_date: "#{temp_contract_date.strftime('%F')}----#{current_year.strftime('%F')}",
                year_contract_volume: year_contract_volume,
                tx: tx,
                closure_count: closure_count,
                closure_count_volume: closure_count_volume,
                closed_year_on_year: closed_year_on_year,
                agent_created_at: agent.created_at.strftime('%F %T')
            }

            # 新签约代理首个签约—代理简称—首个签约日期（yyyy-mm-dd）—代理关联的市场经理
            subject = "代理无签约警告--#{agent.abbreviant}--最近签约日期(#{(temp_contract_date - 1.days).strftime('%F')})--#{agent_manager&.real_name}"

            send_params = {
                to: to_email,
                from: SendcloudSetting.allwin.from,
                template_path: UsersMailer::TEMPLATE_PATH,
                template_name: UsersMailer::TemplateName::SEND_NO_SIGNING_REMIND,
                subject: subject,
                bcc: "wuxianan@atyun.net"
            }
            # 发送邮件
            UsersMailer.send_email(send_params, [], send_email_params).deliver_now! if Agent.is_send_email?(to_email)
          end
        end

        search_two_params = {
            "between_t.agent_created_at" => "#{current_year_strat} #{current_year.strftime('%F')}",
            "t.manager_validity_id" => validity_results.ids
            # FIXME: 目前新建的代理，无上一个财年相关数据 - 暂时屏蔽
            # "mustnil_commission_infos.tx" => CommissionInfo::Tx::Blank
        }
        search_two_results = Agent.get_Tx_results(search_two_params)
        if search_two_results.present?
          search_two_results.each do |agent_info|
            tx_result = tx_results.find { |x| x['name'] == "(空白)" }

            # FIXME: max_contract_date可能是空的情况
            temp_contract_date = Date.parse(agent_info['max_contract_date'].presence || agent_info['agent_created_at']) + 1.days

            # FIXME: 需要注意，这里比较特殊的地方是，不管新建的代理当前财年的预估档位
            # FIXME: 计算相隔的日期是否能被tx_result.value 余 0
            # FIXME: 特别需要注意的是 这里需要加 1 天，并且如果数据为 1 的时候不能当作除数进行计算，因为结果始终都是 1
            date_interval_count = (Date.parse(current_year.strftime('%F')) - temp_contract_date).to_i + 1

            next unless (date_interval_count > 1) && ((date_interval_count % tx_result['value'].to_i) == 0)

            # 发送邮件
            # 获取收件人信息 - 拼接数据
            to_email, agent, agent_manager = Student.relation_agent_emails(agent_info['id'])
            year_contract_volume = 0
            tx = '(空白)'

            closure_count_params = {
                "apply_forms.status" => ApplyForm::Status::CLOSURE,
                "between_apply_forms.closure_time" => "#{temp_contract_date.strftime('%F')} #{current_year.strftime('%F')}",
                "agents.id" => agent_info['id'],
                "school_course_infos.country_id" => country.id
            }
            closure_count = ApplyForm.joins(student: :agent, plans: :school_course_infos).search_by_params(closure_count_params).distinct.count

            closure_count_volume = 0
            closed_year_on_year = '无'

            send_email_params = {
                no_signing_date: "#{temp_contract_date.strftime('%F')}---#{current_year.strftime('%F')}",
                year_contract_volume: year_contract_volume,
                tx: tx,
                closure_count: closure_count,
                closure_count_volume: closure_count_volume,
                closed_year_on_year: closed_year_on_year,
                agent_created_at: agent.created_at.strftime('%F %T')
            }

            # 新签约代理首个签约—代理简称—首个签约日期（yyyy-mm-dd）—代理关联的市场经理
            subject = "代理无签约警告--#{agent.abbreviant}--最近签约日期(#{agent_info['max_contract_date']&.presence || '(无)'})--#{agent_manager&.real_name}"
            send_params = {
                to: to_email,
                from: SendcloudSetting.allwin.from,
                template_path: UsersMailer::TEMPLATE_PATH,
                template_name: UsersMailer::TemplateName::SEND_NO_SIGNING_REMIND,
                subject: subject,
                bcc: "wuxianan@atyun.net"
            }
            # 发送邮件
            UsersMailer.send_email(send_params, [], send_email_params).deliver_now! if Agent.is_send_email?(to_email)
          end
        end
      end
    end
    return response
  end

  def self.get_Tx_results(search_params)
    search_string = Agent.make_search_url(search_params)

    sql = <<~SQL
      with max_contract_date_tables as (
      select agent_portraits_view.id as agent_portraits_view_id,
      COALESCE(to_char(max(apply_forms.contract_date), 'YYYY-MM-DD'), '') AS max_contract_date
      from apply_forms
             left join students
                       on students.id = apply_forms.student_id and students.deleted_at is null
             left join agent_portraits_view on agent_portraits_view.id = students.agent_id
      group by agent_portraits_view.id
      )
      select distinct t.id,
                      commission_infos.tx,
                      max_contract_date_tables.max_contract_date,
                      t.agent_created_at
      from agent_portraits_view t
             left join commission_infos
                       ON commission_infos.owner_type = 'Agent' AND commission_infos.owner_id = t.id AND
                          commission_infos.deleted_at IS NULL
             left join students on students.agent_id = t.id and students.deleted_at is null
             left join apply_forms on apply_forms.student_id = students.id and apply_forms.status = 'closure' 
             and apply_forms.deleted_at is null
             left join max_contract_date_tables on max_contract_date_tables.agent_portraits_view_id = t.id
      #{search_string}
      order by t.id asc;
    SQL

    results = Agent.execute_sql(sql)
    return results
  end

  # 获取代理所有的代理管理员用户
  def self.agent_admin_users(agent_ids)
    User.left_joins(:agents, :roles).where(
        roles: { name: 'agent_admin' },
        agents: { id: agent_ids }
    ).distinct
  end

  ######################################################################################################################
  #
  #
  # 实例方法定义区
  # instance_method definition block
  #
  #
  ######################################################################################################################

  # 上传支付凭证生成附件
  def solve_financial_attachment(user, files, res)
    attachment_group = AttachmentGroup.find_or_create_by!(catalog_type: AttachmentGroup::CatalogType::AGENT_FINANCIAL_INFO, resource: self, operator: user, data_source: '代理财务信息')
    files.each do |file|
      file_params = Attachment.check_file_params(file, res)
      if (attachment = Attachment.where(owner: self, data_source: Attachment::DataSource::AGENT_FINANCIAL_INFO).first).present?
        attachment.update!(file_params)
      else
        attachment = Attachment.new(file_params)
        attachment.attachment_group = attachment_group
        attachment.data_source = Attachment::DataSource::AGENT_FINANCIAL_INFO
        attachment.operator_platform = 'aa'
        attachment.check_status = 1
        attachment.owner = self
        attachment.status = Attachment::Status::Show
        attachment.another_status = Attachment::AnotherStatus::NO_SEND
        attachment.save!
      end
    end
  end

  # * 获取当前代理公司所有子公司对应的代理id
  # * return [agent_ids]
  def agents_through_children_enterprise
    ids = self.enterprise.children.pluck(:resource_id)
    Agent.where(id: ids)
  end

  def enterprise_is_parent?
    !self.enterprise&.parent_id
  end

  module AgentType
    include Dictionary::Module::I18n

    PERSONAL = "personal"

    ENTERPRISE = "enterprise"

    ALL = get_all_values
  end

  private

  def send_email_when_create
    to_emails = self.counsellors.pluck(:email) | [self.sales_manager.email]

    market_specialists_emails = User.joins(:positions, :departments)
                                    .where(positions: { name: '市场专员' })
                                    .where(departments: { name: '销售市场部' })
                                    .where(employees: { status: 'working' })
                                    .pluck(:email)

    cc_emails, _, _ = Student.relation_agent_emails(self)

    send_params = {
        to: to_emails,
        cc: cc_emails.push('agent@aa-intl.com') | market_specialists_emails,
        from: SendcloudSetting.allwin.from,
        template_path: UsersMailer::TEMPLATE_PATH,
        template_name: UsersMailer::TemplateName::AFTER_CREATE_AGENT,
        subject: '有一家新代理建档'
    }

    UsersMailer.send_email(send_params, [], self).deliver_now!
  end
end
