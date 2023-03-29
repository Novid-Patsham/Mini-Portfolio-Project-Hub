# INSTALL AND LOAD PACKAGES ################################

# Install pacman ("package manager") if needed
if (!require("pacman")) install.packages("pacman")

# Load contributed packages with pacman
pacman::p_load(pacman, party, psych, rio, tidyverse, lubridate)
# pacman: for loading/unloading packages
# party: for decision trees
# psych: for many statistical procedures
# rio: for importing data
# tidyverse: R package for Data Science
# lubridate: for working with dates

#?tidyverse


# LOAD AND PREPARE DATA ####################################

### Import CSV files with readr::read_csv() from tidyverse ----

(df1 <- read_csv("Portfolio Project/movies.csv") %>%
        as_tibble())

### Checking Missing Values ----

#df1[rowSums(is.na.data.frame(df1)) > 0,  ]

colSums(is.na.data.frame(df1))

# We will drop the null values from dataframe
df1 <- na.omit(df1)
#df1 <- df1[!is.na(df1$budget),]
colSums(is.na.data.frame(df1))


### Data Cleaning ----

# Change datatype of column
df1$budget <- as.integer(df1$budget)

# Datatypes
#str(df1)
sapply(df1, typeof)

# Extract Year from released
head(sapply(strsplit(df1$released, ' '),'[',3))
df1 <- df1 %>%           
  mutate(                     
    # Create new variables
    year  = as.numeric(sapply(strsplit(df1$released, ' '),'[',3)) 
    # Separate var for year
  )
unique(df1$year)
df1 <- df1[!is.na(df1$year), ]
colSums(is.na.data.frame(df1))
df1 <- subset.data.frame(df1,select = -released)

# Viewing first 5 rows of Sorted dataframe based on gross returns
head(df1[order(df1$gross, decreasing = TRUE), ])

# Finding Correlation ####

### Budget vs Gross ----

#Scatter Plot with regression line
ggplot(df1, aes(budget,gross)) +
  geom_point(size = 2, color = 'red') +
  geom_smooth(method = lm, color = 'blue')

#Scatter plot between the log values of gross and budget
ggplot(df1, aes(log(budget),log(gross))) +
  geom_point(size = 2, color = 'red') +
  geom_smooth(method = lm, color = 'blue')

#Finding the correlation value based on pearson correlation
cor(df1$budget, df1$gross, method = 'pearson')

### Correlation between all numeric columns ----

#Getting the numeric columns
corr_cols = df1[, unlist(lapply(df1, is.numeric))]
sapply(corr_cols, typeof)


#Getting the correlation between those 
colSums(is.na.data.frame(corr_cols))
corr_df = cor(corr_cols[sapply(corr_cols, is.numeric)])

### Heat Map of the correlations ----

if (!require("reshape2")) install.packages("reshape2")
library(reshape2)
#melt(corr_df)
ggplot(melt(corr_df), 
       aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  geom_text(aes(label = round(value,4)), colour = "black", check_overlap = TRUE) +
  scale_fill_gradient(high = "blue", low = "white") +
  theme(axis.title.y = element_blank()) +
  xlab('Movie Features') +
  ggtitle('Correlation Heatmap')

# Relatively high correlation between gross & votes and gross & budget

## Categorical variables vs gross ----

#We will look at the columns 'genre', 'director' and 'company'
cat_df <- select(df1, genre, director, company, gross)
head(cat_df)

# We will get the top 10 companies by gross
comp_gross <- cat_df %>% 
                select(company, gross) %>%
                group_by(company) %>%
                summarise(sum_gross = sum(gross)) %>%
                arrange(desc(sum_gross))

(comp_names <- comp_gross[1:10,]$company)
rm(comp_gross)

# We will get the top 10 directors by gross
director_gross <- cat_df %>% 
  select(director, gross) %>%
  group_by(director) %>%
  summarise(sum_gross = sum(gross)) %>%
  arrange(desc(sum_gross)) %>%
  print(n=10)

(director_names <- director_gross[1:10,]$director)
rm(director_gross)

# We will get the top 10 genres by gross
genre_gross <- cat_df %>% 
  select(genre, gross) %>%
  group_by(genre) %>%
  summarise(sum_gross = sum(gross)) %>%
  arrange(desc(sum_gross)) %>%
  print(n=10)

(genre_names <- genre_gross[1:10,]$genre)
rm(genre_gross)

# We will assign 'Others' to other values that don't 
# match our company/director names
cat_df[!(cat_df$company %in% comp_names), ]$company <- 'Others'
unique(cat_df$company)

cat_df[!(cat_df$director %in% director_names), ]$director <- 'Others'
unique(cat_df$director)

cat_df[!(cat_df$genre %in% genre_names), ]$genre <- 'Others'
unique(cat_df$genre)

# Box plots for director, company and genre vs gross

# Genre
cat_df %>% 
  select(gross, genre) %>%
  melt() %>%
  ggplot(aes(x = genre, 
             y = value)) + 
  geom_boxplot() +
  stat_summary(fun.y = 'mean', color = 'blue') +
  theme(axis.title = element_blank()) +
  ggtitle('Genre - Gross')

# On average (blue dot indicates the mean), Family movies make more than any 
# other and also have wider spread, followed by Animated films. Even the median
# gross is higher for Family, meaning they are the ones usually getting good
# returns. Although some of the highest grossing movies are in Action genre,
# however they are outliers and not the norm. The high values can be associated 
# with the fact that high grossing action films are made by major production 
# companies



# Company
cat_df %>% 
  select(gross, company) %>%
  melt() %>%
  ggplot(aes(x = reorder(company, value, na.rm = TRUE), 
             y = value)) + 
  geom_boxplot() +
  stat_summary(fun.y = 'mean', color = 'blue') +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.25, hjust=0.25),
        axis.title = element_blank()) +
  ggtitle('Company - Gross')

# Given the populrity of Marvel in the recent days, we can see that it makes the 
# most money from its films on average.

cat_df %>% 
  select(gross, company) %>%
  melt() %>%
  group_by(company) %>%
  summarise(comp_count = n()) %>%
  ggplot(aes(x = reorder(company, comp_count, na.rm = TRUE), 
             y = comp_count)) + 
  geom_bar(stat = 'identity', fill = 'skyblue') +
  theme_minimal() +
  coord_flip() + 
  geom_text(aes(label=comp_count), angle = 270, vjust = -0.5) +
  theme(axis.text.x = element_text(angle = 0, vjust = 0.25, hjust=0.25)) +
  labs(y = "Number of films",
       x = NULL)

# We can see that marvel had made very less movies (12) compared to others yet it is 
# has the most gross revenue. It is most probable that Marvel has a
# high correlation with Gross given its popularity.


# Director 
cat_df %>% 
  select(gross, director) %>%
  melt() %>%
  ggplot(aes(x = reorder(director, value, na.rm = TRUE), 
             y = value)) + 
  geom_boxplot() +
  stat_summary(fun.y = 'mean', color = 'blue') +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.25, hjust=0.25),
        axis.title = element_blank()) +
  ggtitle('Director - Gross')

# Finally, although there is some difference between the boxplots of the 
# big-7 directors, smaller directors generally perform decently at the 
# box office in comparison. However, the smaller directors do have fewer box 
# office hits and the spread for the big directors is much wider than the 
# spread for smaller ones. Nevertheless, there is evidence that the 
# name recognition of the big directors still has some clout in Hollywood, Esp 
# Anthony Russo who is associated with Marvel, which as we saw, had the highest
# gross.



