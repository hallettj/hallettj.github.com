function(React) {



    var LikeButton = React.createClass({
        handleClick: function(event) {
            dispatcher.incrementLike(
                this.props.contentId
            );
        },
        render: function() {
            return (
                <span class="control">
                    <a href="#" class="button like"
                                onClick={handleClick}>
                        like
                    </a>
                </span>
            );
        }
    });

    React.renderComponent(
        <LikeButton contentId={whatever.id} />
    );

    var LikeCount = React.createClass({
        render: function() {
            return (
                <span class="count">{count}</span>
            )
        }
    });

    var Article = React.createClass({
        render: function() {
            var id = this.props.id
              , likes = this.props.likes;
            <article>
                {this.props.content}
                <footer>
                    <LikeButton contentId={id} />
                    <LikeCount count={likes} />
                </footer>
            </article>
        }
    });

    function showArticle(article, parentElement) {
        React.renderComponent(
            <Article id={article.id}
                     content={article.content}
                     likes={article.likes} />,
            parentElement
        );
    }

    var DislikeButton = React.createClass({
        render: function() {
            return (
                <span class="control">
                    <a href="#" class="button dislike">
                        dislike
                    </a>
                </span>
            );
        }
    });

    var Content = React.createClass({
        getInitialState: function() {
            return { likes: 0 };
        },
        render: function() {
            return this.transferPropsTo(
                <Article likes={this.state.likes} />
            );
        }
    });

    var content = React.renderComponent(
        <Content id={article.id}
                 content={article.content} />,
        document.getElementById('main');
    );

    function updateLikeCount() {
        $.getJSON('/articles/'+article.id).
        then(function(article) {
            dispatcher.setLikeCount(
                article.id, article.likes
            );
        });
    }
    setInterval(updateLikeCount, 5000);

}
