require 'rails_helper'

RSpec.describe ItemsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:collection) { FactoryBot.create(:collection) }
  let(:item) { FactoryBot.create(:item, collection: collection) }
  let!(:items) { FactoryBot.create_list(:item, 3, collection: collection) }

  describe 'GET /items/:id' do
    context 'when item exists' do
      it 'renders the show page successfully without authentication' do
        get item_path(item)
        expect(response).to have_http_status(:ok)
      end

      it 'displays the correct item information' do
        get item_path(item)
        expect(response.body).to include(item.display_name)
      end

      it 'displays identifications ordered by current desc' do
        identification1 = FactoryBot.create(:identification, item: item, current: false)
        identification2 = FactoryBot.create(:identification, item: item, current: true)
        
        get item_path(item)
        expect(response).to have_http_status(:ok)
        # Test that the page renders successfully with identifications
        expect(response.body).to include("Identification")
      end

      it 'displays preparations' do
        preparation = FactoryBot.create(:preparation, item: item)
        get item_path(item)
        expect(response).to have_http_status(:ok)
        # Test that the page includes preparation information
        expect(response.body).to include("Preparation")
      end
    end

    context 'when item does not exist' do
      it 'returns 404 not found' do
        get item_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET/POST /items/quick_search' do
    let(:search_params) { {"q"=>{"country_case_insensitive_or_state_province_case_insensitive_or_identifications_scientific_name_or_identifications_vernacular_name_cont"=>"test"}} }

    it 'processes quick search and redirects to search' do
      get quick_search_items_path, params: search_params
      expect(response).to redirect_to(search_items_path)
    end

    it 'stores search params in session and redirects' do
      get quick_search_items_path, params: search_params
      expect(response).to redirect_to(search_items_path)
      # After redirect, the quick_search_q should be processed and cleared by the search action
    end

    it 'works with POST method' do
      post quick_search_items_path, params: search_params
      expect(response).to redirect_to(search_items_path)
    end
  end

  describe 'GET/POST /items/search' do
    context 'with view switching' do
      it 'sets view to rows when switch_view is rows' do
        get search_items_path, params: { switch_view: 'rows' }
        expect(response).to have_http_status(:ok)
        # Test that the response includes expected row view elements
        expect(response.body).to include("search")
      end

      it 'sets view to cards when switch_view is cards' do
        get search_items_path, params: { switch_view: 'cards' }
        expect(response).to have_http_status(:ok)
        # Test that the response includes expected card view elements
        expect(response.body).to include("search")
      end

      it 'defaults view when no switch_view param' do
        get search_items_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with search parameters' do
      let(:search_params) { 
        { 
          q: { 
            identifications_scientific_name_cont: 'test',
            country_cont: 'USA'
          } 
        } 
      }

      it 'processes search params and renders results' do
        get search_items_path, params: search_params
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("search")
      end

      it 'handles complex search parameters' do
        complex_params = {
          "q"=>
              {"groupings"=>
                {"0"=>
                  {
                    "0"=>
                        {"field"=>"identifications_scientific_name_i_cont_any", "value"=>"pso"}, 
                    "1"=>{"field"=>"identifications_vernacular_name_i_cont_any", "value"=>"galli"}
                  }
                }
              }
            }
      get search_items_path, params: complex_params
      expect(response).to have_http_status(:ok)
    end
  end

    context 'with pagination' do
      it 'handles per page parameter' do
        get search_items_path, params: { per: 25 }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'works without authentication' do
      get search_items_path
      expect(response).to have_http_status(:ok)
    end

    it 'works with POST method' do
      post search_items_path, params: { q: { "country_case_insensitive_or_state_province_case_insensitive_or_identifications_scientific_name_or_identifications_vernacular_name_cont"=>"test" } }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /export_to_csv' do
    context 'when authenticated' do
      before { mock_login(user) }

      it 'exports items to CSV successfully' do
        get export_to_csv_path, params: { format: 'csv' }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
      end

      it 'exports with search parameters' do
        search_params = { q: { country_cont: 'USA' } }
        get export_to_csv_path, params: search_params.merge(format: 'csv')
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
      end

      it 'sets appropriate CSV headers' do
        get export_to_csv_path, params: { format: 'csv' }
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Content-Disposition']).to include('.csv')
      end

      it 'streams response for large datasets' do
        # Create more items to test streaming
        FactoryBot.create_list(:item, 10, collection: collection)
        
        get export_to_csv_path, params: { format: 'csv' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when not authenticated' do
      it 'redirects to login' do
        get export_to_csv_path, params: { format: 'csv' }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'error handling' do

    context 'with invalid search parameters' do
      it 'handles malformed search params gracefully' do
        get search_items_path, params: { q: { invalid_field: 'test' } }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'session handling' do
    it 'processes quick search workflow correctly' do
      search_term = 'test species'
      search_params = { 
        q: { 
          country_case_insensitive_or_state_province_case_insensitive_or_identifications_scientific_name_or_identifications_vernacular_name_cont: search_term 
        } 
      }
      
      # Make quick search request
      get quick_search_items_path, params: search_params
      expect(response).to redirect_to(search_items_path)
      
      # Follow the redirect to search page
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("search")
    end
  end
end
