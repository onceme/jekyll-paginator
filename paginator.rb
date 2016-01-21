# Simple plugin to generate pages for specific categories.
# Categories has to be defined in your _config.yml
# Parameters:
# - 'pagination' how many posts per page
# - 'layout' which layout to use
# - 'generate_all' boolean, true if every category should be generated
# - 'directory' target directory of generated pages
# - 'details' list of categories to generate pages for, each one can have
#   title, layout, pagination and weight (which can be used within your navigation template
#   for sorting)
#
# Template data:
# - 'page.posts' list of posts
# - 'page.nextUrl' url to next page, only available if next page exists
# - 'page.prevUrl' url to previous page, only available if previous page exists
# - 'page.category' your category
# - 'page.weight' your weight
# - 'page.title' your title
# - 'page.number' the current page number
# - 'page.pages' the maximum number of pages
# - 'page.more' boolean, true if there is one more site
#
# Example configuration:
#   categories:
#     layout: category.html
#     pagination: 5
#     directory: categories
#     details:
#       cat1:
#         title: Cat1
#         pagination: 10
#         weight: 25
#       cat2:
#         title: Cat2
#         weight: 50
#       cat3:
#         title: Cat3
#         weight: 75

module Jekyll
  # Page class it-self, contains data through this specific list of posts
  # like nextUrl, prevUrl, number of posts or page number
  class PostSubSetPage < Page
      def initialize(site, base, dir, detail, page, posts, more, pages)
          @site = site
          @base = base
          @dir = dir
          @name = "page#{page}.html"

          # Define data which can be used in category.html
          self.process(@name)
          self.read_yaml(File.join(base, '_layouts'), detail['layout'])
          self.data['category'] = detail['category']
          self.data['weight'] = detail['weight']
          self.data['title'] = detail['title']
          self.data['posts'] = posts
          self.data['number'] = page
          self.data['pages'] = pages
          self.data['more'] = more
          self.data['sitemap'] = false

          # Add next button for navigation
          if more
            nextNumber = page + 1
            self.data['nextUrl'] = File.join('', dir, "page#{nextNumber}")
          end
          # Add prev button for navigation
          if page > 1
              prevNumber = page - 1
              self.data['prevUrl'] = File.join('', dir, "page#{prevNumber}")
          end
      end
  end

  # Page generatore, iterates through all available posts and creates pages
  # for configurated categories. Pages are sorted descending by date
  class PaginatorGenerator < Generator
    safe true

    def generateList(site, list, dir, category, details, config)
        detail = details[category] || {}
        detail['pagination'] = detail['pagination'] || config['pagination'] || 5
        detail['category'] = category
        detail['layout'] = detail['layout'] || config['layout'] || 'category.html'

        # Sort by date descending
        list = list.sort! { |a,b| b.date <=> a.date }

        # Put each page file in a subfolder of dir
        dir = File.join(dir, category)

        # Calculate number of pages
        pages = (detail['pagination'] / list.length).ceil

        # Iterate through all posts
        number = 1
        counter = 0
        posts = []
        list.each do |post|
          posts.push(post)
          counter += 1
          if posts.length == detail['pagination']
            site.pages << PostSubSetPage.new(site, site.source, dir, detail, number, posts, counter < list.length, pages)
            number += 1
            posts = []
          end
        end
        if posts.length != 0
          site.pages << PostSubSetPage.new(site, site.source, dir, detail, number, posts, false, pages)
        end
    end

    def generate(site)
        categories = {}
        site.posts.each {|p| p.categories.each {|c| (categories[c] ||= []) << p } }

        # Read some configurations
        config = site.config['categories'] || {}
        dir = config['directory'] || 'categories'
        generateAll = config['generate_all'] || false
        details = config['details'] || {}

        # Keep generated files
        site.config['keep_files'] << dir unless site.config['keep_files'].include?(dir)

        # Generate pages per category
        categories.each do |category, list|
          if details[category] || generateAll
            self.generateList(site, list, dir, category, details, config)
          end
        end

        # Generate pages for all
        # self.generateList(site, site.posts, dir, 'all', details, config)
    end
  end
end
