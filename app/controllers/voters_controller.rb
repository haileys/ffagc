class VotersController < ApplicationController
  load_and_authorize_resource only: [:show]

  before_filter :initialize_grants

  def show
  end

  def signup
  end

  def create
    if Voter.exists?(email: voter_params[:email.downcase])
      flash[:warning] = "The email address #{voter_params[:email.downcase]} already exists in our system"
      render "signup_failure"
      return
    end

    @voter = Voter.new(voter_params)

    @voter.email = @voter.email.downcase

    if @voter.save
      # save survey
      voter_survey = VoterSurvey.new(voter_survey_params)
      voter_survey.voter_id = @voter.id
      voter_survey.save

      # save participation info
      meetings = collated_meetings

      voter_participation_params.each do |collated_id, can_do|
        if can_do == "0"
          next
        end
        # We have to map from collated index to the list of grants.
        # This is a gross n*m walk through the lists, but we are talking very
        # small lists.
        meetings.each do |dates, data|
          if data['id'].to_s != collated_id
            next
          end
          data['grant_ids'].each do |gid|
            # sanity check that the grant id is real.
            if Grant.find(gid) == nil
              next
            end
            grants_voter = GrantsVoter.new
            grants_voter.voter_id = @voter.id
            grants_voter.grant_id = gid
            grants_voter.save
          end
        end
      end

      # Send email
      begin
        UserMailer.account_activation("voters", @voter).deliver_now
        logger.info "email: voter account activation sent to #{@voter.email}"
      rescue
        flash[:warning] = "Error sending email confirmation"
        render "signup_failure"
        return
      end

      render "signup_success"
    else
      render "signup_failure"
    end
  end

  def update
    # could allow for (timing based) Voter enumeration
    @voter = Voter.find(params[:id])

    unless can? :manage, GrantsVoter.new(voter: @voter)
      redirect_to '/'
      return
    end

    voter_participation_params.each do |grant_id, can_do|
      unless Grant.find(grant_id).present?
        next
      end

      if can_do == '0'
        if GrantsVoter.exists?(voter_id: @voter.id, grant_id: grant_id)
          GrantsVoter.find_by(voter_id: @voter.id, grant_id: grant_id).destroy
        end
      else
        if GrantsVoter.exists?(voter_id: @voter.id, grant_id: grant_id)
          next
        end

        grants_voter = GrantsVoter.create!(voter: @voter, grant_id: grant_id)
      end
    end

    redirect_to controller: 'admins', action: 'voters'
  end

  def index
    unless can? :vote, GrantSubmission.new
      flash[:warning] = 'You are not able to vote'
      redirect_to '/'
      return
    end

    # TODO: use scope
    @grant_submissions = GrantSubmission.where(grant_id: voter_active_vote_grants(current_voter.id))

    # TODO: sort in scope or add sorting scope
    @grant_submissions = @grant_submissions.sort { |a,b| [a.name] <=> [b.name] }

    @votes = Hash.new

    @grant_submissions.each do |gs|
      gs.class_eval do
        attr_accessor :assigned
      end

      vote = current_voter.votes.where(grant_submission: gs).first_or_create

      @votes[gs.id] = vote

      #assignments
      vsa = current_voter.voter_submission_assignments.where(grant_submission: gs)

      if vsa.exists?
        gs.assigned = 1
      else
        gs.assigned = 0
      end
    end

    # TODO: use scopes
    @grant_submissions_assigned = @grant_submissions.select{|gs| gs.assigned == 1}
    @grant_submissions_unassigned = @grant_submissions.select{|gs| gs.assigned == 0}

    # TODO: sort in scope or add sorting scope
    @grant_submissions_unassigned.sort_by {|gs| gs.grant_id}

    if params[:all] == "true"
      @show_all = true
      @grant_submissions_display = @grant_submissions
    else
      @show_all = false
      @grant_submissions_display = @grant_submissions_assigned
    end
  end

  def vote
    @grant_submissions = GrantSubmission.where(grant_id: active_vote_grants)

    # Realistically, only one var will ever change at a time because the user
    # can only change one thing at once.  Really the submit function should
    # just pass the one item that changed.
    @grant_submissions.each do |gs|
      vote = Vote.where("voter_id = ? AND grant_submission_id = ?", current_voter.id, gs.id).take
      # nil means "was not set".  If the user sets to blank, it will be " ".
      if params['t'][gs.id.to_s] == nil
        next
      end

      changed = false
      if vote.score_t.to_s != params['t'][gs.id.to_s]
        vote.score_t = params['t'][gs.id.to_s]
        changed = true
      end
      if vote.score_c.to_s != params['c'][gs.id.to_s]
        vote.score_c = params['c'][gs.id.to_s]
        changed = true
      end
      if vote.score_f.to_s != params['f'][gs.id.to_s]
        vote.score_f = params['f'][gs.id.to_s]
        changed = true
      end
      if changed
        vote.save
      end
    end

    render :json => { }
  end

  private

  def initialize_grants
    @grants = Grant.all
  end

  def voter_params
    params.require(:voter).permit(:name, :password_digest, :password, :password_confirmation, :email)
  end

  def voter_survey_params
    params.require(:survey).permit(:has_attended_firefly, :not_applying_this_year,
        :will_read, :will_meet, :has_been_voter, :has_participated_other,
        :has_received_grant, :has_received_other_grant, :how_many_fireflies,
        :signed_agreement)
  end

  def voter_participation_params
    params.require(:grants_voters)
  end
end
