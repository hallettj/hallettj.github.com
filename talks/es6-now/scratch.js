/*jshint esnext:true, asi:true */

(function() {


    import _ from 'lodash'

    export default function MyClass(opts) {
        this.opts = _.assign({}, defaults, opts)
    }
    var defaults = {
        /* ... */
    }




    define(['lodash'], function(_) {
        function MyClass(opts) {
            this.opts = _.assign({}, this.defaults, opts)
        }
        MyClass.prototoype.defaults = {
            /* ... */
        }
        return MyClass;
    })



    var person = {
        name: "Harriet",
        occupation: "hacker",
        twitter: "@sue"
    }

    var { name, occupation, twitter } = person

    assert(
        name === "Sue"
    )



    import _ from 'lodash'

    export evenSum
    export oddSum
    export thirdFunc

    function evenSum(xs) {
        _.reduce(_.filter(_.map(xs, Number), isEven),
                 (sum, x) => sum + x,
                 0
        );
    }
    function oddSum(xs) { /* ... */ }
    function thirdFunc(xs) { /* ... */ }





    import { reduce, filter, map } from 'lodash'

    export {
        evenSum,
        oddSum,
        thirdFunc
    }

    function evenSum(xs) {
        reduce(filter(map(xs, Number), isEven),
                 (sum, x) => sum + x,
                 0
        );
    }
    function oddSum(xs) { /* ... */ }
    function thirdFunc(xs) { /* ... */ }



})
