import UIKit

class MyCustomCell: UICollectionViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var filmTitleLabel: UILabel!
    @IBOutlet weak var releaseYearLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    struct MyModel {
        let filmTitle: String
        let releaseYeah: String
        let rating: String
        let posterPreview: String
        let isImageOnly: Bool
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        filmTitleLabel.numberOfLines = 0
        filmTitleLabel.lineBreakMode = .byWordWrapping
        filmTitleLabel.font = UIFont.systemFont(ofSize: 16)

        releaseYearLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.font = UIFont.systemFont(ofSize: 14)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func configure(with model: MyModel) {
        filmTitleLabel.text = model.filmTitle
        releaseYearLabel.text = model.releaseYeah
        ratingLabel.text = model.rating
        posterImageView.image = UIImage(named: model.posterPreview)
    }

}
