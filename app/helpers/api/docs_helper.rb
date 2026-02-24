module Api::DocsHelper
  def nav_data
    {
      api_docs: {
        name: "Index",
        id: "index"
      },
      api_docs_authentication: {
        name: "Authentication",
        id: "authentication"
      },
      api_docs_general_errors: {
        name: "General errors",
        id: "general_errors"
      },
      api_docs_bugs: {
        name: "Bug reports",
        id: "bugs"
      },
      api_docs_languages: {
        name: "Languages",
        id: "languages"
      },
      api_docs_users: {
        name: "Users",
        id: "users",
        subsections: {
          username_validation: "Username validation",
          create: "Create",
          exists: "Exists",
          delete_token: "Delete token",
          delete: "Delete",
          login: "Login",
          refresh: "Refresh",
          data: "Data",
          search: "Search",
          user_quizzes: "Quizzes",
          favorites: "Favorites",
          public: "Public",
          update: "Update",
          settings: "Settings"
        }
      },
      api_docs_quizzes: {
        name: "Quizzes",
        id: "quizzes",
        subsections: {
          create: "Create",
          delete_token: "Delete token",
          delete: "Delete",
          data: "Data",
          search: "Search",
          update: "Update",
          favorite_quiz: "Favorite quiz",
          favorites: "Favorite translations",
          score: "Score",
          sync_score: "Sync score",
          reset_score: "Reset score",
          report: "Report"
        }
      }
    }
  end

  def name(array)
    array.last[:name]
  end

  def id(array)
    array.last[:id]
  end

  def subsections?(array)
    array.last[:subsections].present?
  end

  def subsections(array)
    array.last[:subsections]
  end
end
